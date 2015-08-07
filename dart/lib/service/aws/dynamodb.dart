library triton_note.service.aws.dynamodb;

import 'dart:async';
import 'dart:convert';
import 'dart:js';
import 'dart:math';

import 'package:logging/logging.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/service/aws/cognito.dart';
import 'package:triton_note/settings.dart';

final _logger = new Logger('DynamoDB');

String _stringify(JsObject obj) => context['JSON'].callMethod('stringify', [obj]);

typedef T _RecordReader<T>(Map map);
typedef Map _RecordWriter<T>(T obj);

class DynamoDB {
  static const CONTENT = "CONTENT";
  static const COGNITO_ID = "COGNITO_ID";

  static Future<String> get cognitoId async => (await CognitoIdentity.identity).id;
  static final client = new JsObject(context["AWS"]["DynamoDB"], []);

  static String createRandomKey() {
    final random = new Random(new DateTime.now().toUtc().millisecondsSinceEpoch);
    final list = new List.generate(32, (i) => random.nextInt(35).toRadixString(36));
    return list.join();
  }

  static final _Table TABLE_CATCH = new _Table("CATCH", "CATCH_ID", (Map map) {
    return new Fishes.fromMap(map[CONTENT])..reportId = map['REPORT_ID'];
  }, (Fishes obj) {
    return {}
      ..[CONTENT] = new Map.from(obj.asMap)
      ..['REPORT_ID'] = obj.reportId;
  });
  static final _Table TABLE_REPORT = new _Table("REPORT", "REPORT_ID", (Map map) {
    return new Report.fromMap(map[CONTENT])
      ..id = map['REPORT_ID']
      ..dateAt = new DateTime.fromMillisecondsSinceEpoch(map['DATE_AT'], isUtc: true);
  }, (Report obj) {
    return {}
      ..[CONTENT] = new Map.from(obj.asMap)
      ..['REPORT_ID'] = obj.id
      ..['DATE_AT'] = obj.dateAt.toUtc().millisecondsSinceEpoch;
  });
}

class _Table<T extends DBRecord> {
  final String tableName;
  final String ID_COLUMN;
  final _RecordReader<T> reader;
  final _RecordWriter<T> writer;

  _Table(this.tableName, this.ID_COLUMN, this.reader, this.writer);

  Future<JsObject> _invoke(String methodName, Map param) async {
    param['TableName'] = "${(await Settings).appName}.${tableName}";
    _logger.finest(() => "Invoking '${methodName}': ${param}");
    final result = new Completer();
    DynamoDB.client.callMethod(methodName, [
      new JsObject.jsify(param),
      (error, data) {
        if (error != null) {
          _logger.warning("Failed to ${methodName}: ${error}");
          result.completeError(error);
        } else {
          _logger.finest("Result(${methodName}): ${_stringify(data)}");
          result.complete(data);
        }
      }
    ]);
    return result.future;
  }

  Future<Map<String, Map<String, String>>> _makeKey(String id) async {
    final key = {DynamoDB.COGNITO_ID: {'S': await DynamoDB.cognitoId}};
    if (id != null && ID_COLUMN != null) key[ID_COLUMN] = {'S': id};
    return key;
  }

  Future<T> get(String id) async {
    final data = await _invoke('getItem', {'Key': await _makeKey(id), 'ProjectionExpression': DynamoDB.CONTENT});
    final item = data['Item'];
    if (item == null) return null;

    final map = _ContentDecoder.fromDynamoMap(item);
    return reader(map);
  }

  Future<Null> put(T obj) async {
    final id = DynamoDB.createRandomKey();
    final item = _ContentEncoder.toDynamoMap(writer(obj))..addAll(await _makeKey(id));
    await _invoke('putItem', {'Item': item});

    obj.id = id;
  }

  Future<Null> update(T obj) async {
    final map = _ContentEncoder.toDynamoMap(writer(obj));
    final attrs = {};
    map.forEach((key, valueMap) {
      attrs[key] = {'Action': 'PUT', 'Value': valueMap};
    });
    await _invoke('updateItem', {'Key': await _makeKey(obj.id), 'AttributeUpdates': attrs});
  }

  Future<Null> delete(String id) async {
    await _invoke('deleteItem', {'Key': await _makeKey(id)});
  }

  PagingDB createPager(String indexName, String hashKeyName, String hashKeyValue, bool forward) {
    return new PagingDB(this, indexName, forward, hashKeyName, hashKeyValue);
  }
}

class PagingDB<T> {
  final _Table table;
  final String indexName, hashKeyName;
  final Map hashKeyValue;
  final bool isForward;

  PagingDB(this.table, this.indexName, this.isForward, this.hashKeyName, String hashKeyValue)
      : this.hashKeyValue = new Map.unmodifiable(_ContentEncoder.encode(hashKeyValue));

  Map _lastEvaluatedKey;
  bool get hasMore => _lastEvaluatedKey == null || _lastEvaluatedKey.isNotEmpty;

  void reset() {
    _lastEvaluatedKey = null;
  }

  Future<List<T>> more(int pageSize) async {
    if (!hasMore) return [];

    final params = {
      'Limit': pageSize,
      'ScanIndexForward': isForward,
      'IndexName': indexName,
      'KeyConditionExpression': "#N1 = :V1",
      'ExpressionAttributeNames': {'#N1': hashKeyName},
      'ExpressionAttributeValues': {':V1': hashKeyValue}
    };
    if (_lastEvaluatedKey != null) {
      params['ExclusiveStartKey'] = _lastEvaluatedKey;
    }
    final data = await table._invoke('query', params);

    _lastEvaluatedKey = data['LastEvaluatedKey'];
    if (_lastEvaluatedKey == null) _lastEvaluatedKey = const {};

    return data['Items'].map(_ContentDecoder.fromDynamoMap).map(table.reader).toList();
  }
}

class _ContentDecoder {
  static decode(Map<String, Object> valueMap) {
    assert(valueMap.length == 1);
    final t = valueMap.keys.first;
    final value = valueMap[t];
    _logger.finest(() => "Decoding value: '${t}': ${value}");
    switch (t) {
      case 'M':
        return fromDynamoMap(value as Map);
      case 'L':
        return (value as List).map((a) => decode(a));
      case 'S':
        return value as String;
      case 'N':
        return num.parse(value.toString());
    }
  }

  static Map fromDynamoMap(dmap) {
    _logger.finest(() => "Decoding content: ${dmap}");
    if (dmap is JsObject) return fromDynamoMap(JSON.decode(_stringify(dmap)));

    final result = {};
    dmap.forEach((key, Map valueMap) {
      result[key] = decode(valueMap);
    });
    _logger.finest(() => "Decoded map: ${result}");
    return result;
  }
}
class _ContentEncoder {
  static encode(value) {
    if (value is Map) return {'M': toDynamoMap(value)};
    if (value is List) return {'L': value.map((a) => encode(a))};
    if (value is String) return {'S': value};
    if (value is num) return {'N': value.toString()};
  }
  static Map toDynamoMap(Map map) {
    final result = {};
    map.forEach((key, value) {
      result[key] = encode(value);
    });
    return result;
  }
}
