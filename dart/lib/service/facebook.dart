library triton_note.service.facebook;

import 'dart:async';
import 'dart:convert';
import 'dart:js';

import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;

import 'package:triton_note/settings.dart';
import 'package:triton_note/service/aws/cognito.dart';
import 'package:triton_note/model/report.dart';

class FBConnect {
  static final _logger = new Logger('FBConnect');

  static Future _call(String name, List args) {
    final completer = new Completer<String>();
    args.insert(0, (error, result) {
      _logger.finest(() => 'Result of plugin.FBConnect.${name}: ${result}, error: ${error}');
      if (result != null) {
        result = JSON.decode(context['JSON'].callMethod('stringify', [result]));
      }

      if (error == null) {
        completer.complete(result);
      } else {
        completer.completeError(error);
      }
    });
    context['plugin']['FBConnect'].callMethod(name, args);
    return completer.future;
  }

  static Future<bool> login() async {
    try {
      final token = await _call('login', []) as String;
      final cred = await CognitoIdentity.joinFacebook(token);
      _logger.finest(() => "Logged in: cognito id: ${cred.id}");
      return cred.hasFacebook();
    } catch (ex) {
      _logger.warning(() => "Failed to connect to Facebook: ${ex}");
      return false;
    }
  }

  static Future<bool> logout() async {
    try {
      await _call('logout', []);
      final cred = await CognitoIdentity.dropFacebook();
      _logger.finest(() => "Logged out: cognito id: ${cred.id}");
      if (cred.hasFacebook()) {
        _logger.warning(() => "Failed to disconnect from Facebook. Still connected.");
        return false;
      } else {
        return true;
      }
    } catch (ex) {
      _logger.warning(() => "Failed to disconnect from Facebook: ${ex}");
      return false;
    }
  }

  static Future<String> grantPublish() => _call('login', ['publish_actions']);
  static Future<String> getName() => _call('getName', []);
  static Future<Map> getToken() => _call('getToken', []);
}

class _FBSettings {
  static Future<_FBSettings> load() async {
    final Map map = (await AuthorizedSettings)['facebook'];
    return new _FBSettings(map);
  }

  _FBSettings(this._map);

  final Map _map;

  String get hostname => _map['host'];
  String get appName => _map['appName'];
  String get appId => _map['appId'];
  String get imageTimeout => _map['imageTimeout'];
  String get actionName => _map['actionName'];
  String get objectName => _map['objectName'];
}

class FBPublish {
  static final _logger = new Logger('FBPublish');

  static publish(Report report) async {
    _logger.fine(() => "Publishing report: ${report.id}");

    final cred = await CognitoIdentity.credential;
    final settings = await Settings;
    final fbSettings = await _FBSettings.load();

    api(String name, Map info) {
      final json = JSON.encode(info);
      final urlen = Uri.encodeFull(json);
      final base64 = new Base64Encoder().convert(new AsciiEncoder().convert(urlen));
      return "https://api.fathens.org/triton-note/open_graph/${name}/${base64}";
    }
    apiSpot() => api('spot', {
          'region': settings.awsRegion,
          'table_report': "${settings.appName}.REPORT",
          'cognitoId': cred.id,
          'reportId': report.id
        });
    apiReport() => api('catch_report', {
          'region': settings.awsRegion,
          'bucketName': settings.s3Bucket,
          'urlTimeout': fbSettings.imageTimeout,
          'table_report': "${settings.appName}.REPORT",
          'table_catch': "${settings.appName}.CATCH",
          'cognitoId': cred.id,
          'reportId': report.id
        });

    final params = {
      'fb:explicitly_shared': ['true'],
      'message': report.comment,
      'place': apiSpot(),
      fbSettings.objectName: apiReport(),
      "image[0][url]": report.photo.original.url,
      "image[0][user_generated]": 'true'
    };

    final token = await FBConnect.grantPublish();
    final url = "${fbSettings.hostname}/me/${fbSettings.appName}:${fbSettings.actionName}?access_token=${token}";
    final result = await new http.Client().post(url, body: params);

    if (result.statusCode % 100 != 2) {
      throw result.body;
    } else {
      final Map obj = JSON.decode(result.body);
      if (!obj.containsKey('id')) {
        throw obj;
      } else {
        final published = obj['id'];
        _logger.info(() => "Report(${report.id}) is published: ${published}");
      }
    }
  }
}
