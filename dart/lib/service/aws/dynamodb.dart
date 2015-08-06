library triton_note.service.aws.dynamodb;

import 'dart:async';
import 'dart:convert';
import 'dart:js';
import 'dart:math';

import 'package:logging/logging.dart';

import 'package:triton_note/service/aws/cognito.dart';
import 'package:triton_note/settings.dart';

final _logger = new Logger('DynamoDB');

String _stringify(JsObject obj) => context['JSON'].callMethod('stringify', [obj]);

class DynamoDB {
  static const CONTENT = "CONTENT";
  static const COGNITO_ID = "COGNITO_ID";

  static Future<String> get cognitoId async => (await Cognito.identity).id;
  static final client = new JsObject(context["AWS"]["DynamoDB"], []);

  static String createRandomKey() {
    final random = new Random(new DateTime.now().toUtc().millisecondsSinceEpoch);
    final list = new List.generate(32, (i) => random.nextInt(35).toRadixString(36));
    return list.join();
  }

  static final DynamoDB TABLE_CATCH = new DynamoDB("CATCH");
  static final DynamoDB TABLE_REPORT = new DynamoDB("REPORT");
  static final DynamoDB TABLE_USER = new DynamoDB("USER");

  final String tableName;

  DynamoDB(this.tableName);

  Future<JsObject> invoke(String methodName, Map param) async {
    param['TableName'] = "${(await Settings).appName}.${tableName}";
    _logger.finest(() => "Invoking '${methodName}': ${param}");
    final result = new Completer();
    client.callMethod(methodName, [
      new JsObject.jsify(param),
      (error, data) {
        if (error) {
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

  Future<Map<String, Map<String, String>>> makeKey(String id) async {
    final key = {COGNITO_ID: {'S': await cognitoId}};
    if (id != null) key["${tableName}_ID"] = {'S': id};
    return key;
  }

  Future<List> scan(Map param) async {
    final data = await invoke('scan', param);
    return data['Items'];
  }

  Future<Map> get([String id = null]) async {
    final data = await invoke('getItem', {'Key': await makeKey(id), 'ProjectionExpression': CONTENT});
    final item = data['Item'];
    if (item == null) return null;

    final map = _ContentDecoder.fromDynamoMap(item);
    var content = map[CONTENT];
    if (content == null) content = {};
    if (id != null) content['id'] = id;
    return content;
  }

  Future<Map> put(Map<String, Object> content, [Map<String, Object> alpha = const {}]) async {
    final id = alpha.containsKey('id') ? alpha['id'] : createRandomKey();
    final item = await makeKey(id);
    item[CONTENT] = {'M': _ContentEncoder.toDynamoMap(content)..remove('id')};
    item.addAll(_ContentEncoder.toDynamoMap(alpha));
    await invoke('putItem', {'Item': item});
    return new Map.from(content)..['id'] = id;
  }

  Future<Null> update(Map<String, Object> content, [Map<String, Object> alpha = const {}]) async {
    final attrs = {CONTENT: {'Action': 'PUT', 'Value': {'M': _ContentEncoder.toDynamoMap(content)..remove('id')}}};
    _ContentEncoder.toDynamoMap(alpha).forEach((key, valueMap) {
      attrs[key] = {'Action': 'PUT', 'Value': valueMap};
    });
    await invoke('updateItem', {'Key': await makeKey(content['id']), 'AttributeUpdates': attrs});
  }

  Future<Null> delete([String id = null]) async {
    await invoke('deleteItem', {'Key': await makeKey(id)});
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
    if (value is num) return {'S': value.toString()};
  }
  static Map toDynamoMap(Map map) {
    final result = {};
    map.forEach((key, value) {
      result[key] = encode(value);
    });
    return result;
  }
}
