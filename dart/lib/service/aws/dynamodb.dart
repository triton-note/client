library triton_note.service.aws.dynamodb;

import 'dart:async';
import 'dart:js';
import 'dart:math';

import 'package:logging/logging.dart';

import 'package:triton_note/service/aws/cognito.dart';
import 'package:triton_note/settings.dart';

final _logger = new Logger('DynamoDB');

String _stringify(JsObject obj) => context['JSON'].callMethod('stringify', [obj]);

class DynamoDB {
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
    final key = {'COGNITO_ID': {'S': await cognitoId}};
    if (id != null) key["${tableName}_ID"] = {'S': id};
    return key;
  }

  Future<List> scan(Map param) async {
    final data = await invoke('scan', param);
    return data['Items'];
  }

  Future<Map> get([String id = null]) async {
    final data = await invoke('getItem', {'Key': await makeKey(id), 'ProjectionExpression': "CONTENT"});
    final item = data['Item'];
    if (item == null) return null;

    var content = item['CONTENT'];
    if (content == null) content = {};
    if (id != null) content['id'] = {'S': id};
    return content;
  }

  Future<Map> put(Map<String, Object> content, [Map<String, Object> alpha = const {}]) async {
    final item = await makeKey(createRandomKey());
    item['CONTENT'] = {'M': new Map.from(content)..remove('id')};
    item.addAll(alpha);
    await invoke('putItem', {'Item': item});
    return new Map.from(content)..['id'] = item["${tableName}_ID"];
  }

  Future<Null> update(Map<String, Object> content, [Map<String, Object> alpha = const {}]) async {
    final attrs = {'CONETNT': {'Action': 'PUT', 'Value': {'M': new Map.from(content)..remove('id')}}};
    alpha.forEach((key, valueMap) {
      attrs[key] = {'Action': 'PUT', 'Value': valueMap};
    });
    await invoke('updateItem', {'Key': await makeKey(content['id']), 'AttributeUpdates': attrs});
  }

  Future<Null> delete([String id = null]) async {
    await invoke('deleteItem', {'Key': await makeKey(id)});
  }
}
