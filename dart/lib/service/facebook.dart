library triton_note.service.facebook;

import 'dart:async';
import 'dart:convert';
import 'dart:js';

import 'package:logging/logging.dart';
import 'package:http/browser_client.dart' as http;

import 'package:triton_note/settings.dart';
import 'package:triton_note/service/aws/cognito.dart';
import 'package:triton_note/model/report.dart';

class FBConnect {
  static final _logger = new Logger('FBConnect');

  static Future _call(String name, List args) {
    final completer = new Completer<String>();
    args.insert(0, (error, result) {
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

  static Future<String> _login(List<String> perms) async {
    final token = await _call('login', perms) as String;
    final cred = await CognitoIdentity.joinFacebook(token);
    if (!cred.hasFacebook()) throw "Failed to connect to Facebook.";
    return token;
  }

  static Future<Null> logout() async {
    await _call('logout', []);
    final cred = await CognitoIdentity.dropFacebook();
    if (cred.hasFacebook()) throw "Failed to disconnect from Facebook. Still connected.";
  }

  static Future<String> login() => _login([]);
  static Future<String> grantPublish() => _login(['publish_actions']);
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

  static Future<String> publish(Report report) async {
    _logger.fine(() => "Publishing report: ${report.id}");

    final token = await FBConnect.grantPublish();
    final cred = await CognitoIdentity.credential;
    final settings = await Settings;
    final fbSettings = await _FBSettings.load();

    og(String name, Map info) {
      final urlen = Uri.encodeFull(JSON.encode(info));
      final base64 = new Base64Encoder().convert(new AsciiEncoder().convert(urlen));
      return "https://api.fathens.org/triton-note/open_graph/${name}/${base64}";
    }

    final params = {
      'fb:explicitly_shared': ['true'],
      'message': report.comment,
      "image[0][url]": await report.photo.original.makeUrl(),
      "image[0][user_generated]": 'true',
      'place': og('spot', {
        'region': settings.awsRegion,
        'table_report': "${settings.appName}.REPORT",
        'cognitoId': cred.id,
        'reportId': report.id
      }),
      fbSettings.objectName: og('catch_report', {
        'region': settings.awsRegion,
        'bucketName': settings.s3Bucket,
        'urlTimeout': fbSettings.imageTimeout,
        'table_report': "${settings.appName}.REPORT",
        'table_catch': "${settings.appName}.CATCH",
        'cognitoId': cred.id,
        'reportId': report.id
      })
    };

    final url = "${fbSettings.hostname}/me/${fbSettings.appName}:${fbSettings.actionName}";
    _logger.fine(() => "Posting to ${url}: ${params}");

    final result = await new http.BrowserClient().post("${url}?access_token=${token}", body: params);
    _logger.fine(() => "Result of posting to facebook: ${result}");

    if (result.statusCode % 100 != 2) {
      throw result.body;
    } else {
      final Map obj = JSON.decode(result.body);
      if (!obj.containsKey('id')) {
        throw obj;
      } else {
        final published = obj['id'];
        _logger.info(() => "Report(${report.id}) is published: ${published}");
        return published;
      }
    }
  }
}
