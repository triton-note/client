library triton_note.service.aws.dynamodb;

import 'dart:async';
import 'dart:js';

import 'package:logging/logging.dart';

import 'package:triton_note/service/aws/cognito.dart';
import 'package:triton_note/settings.dart';

final _logger = new Logger('DynamoDB');

class DynamoDB {
  static Future<String> get cognitoId async => (await Cognito.identity).id;
  static final client = new JsObject(context["AWS"]["DynamoDB"], []);

  static final TABLE_CATCH = new DynamoDB("CATCH");
  static final TABLE_REPORT = new DynamoDB("REPORT");
  static final TABLE_USER = new DynamoDB("USER");

  final String tableName;

  DynamoDB(this.tableName);

  Future<JsObject> _invoke(String methodName, Map param) async {
    param['TableName'] = "${await Settings.appName}.${tableName}";
    final result = new Completer();
    client.callMethod(methodName, [
      new JsObject.jsify(param),
      (error, data) {
        if (error) {
          result.completeError(error);
        } else {
          result.complete(data);
        }
      }
    ]);
    return result.future;
  }

  Future<List> scan(Map param) async {
    final data = await _invoke('scan', param);
    return data['Items'];
  }
}
