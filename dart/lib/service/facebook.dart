library triton_note.service.facebook;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js';

import 'package:logging/logging.dart';

import 'package:triton_note/settings.dart';
import 'package:triton_note/service/aws/cognito.dart';
import 'package:triton_note/model/report.dart';
import 'package:triton_note/util/fabric.dart';

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
    final fb = await _FBSettings.load();

    og(String name, [Map info = const {}]) {
      final url = "https://api.fathens.org/triton-note/open_graph/${name}";
      final data = {
        'url': url,
        'region': settings.awsRegion,
        'table_report': "${settings.appName}.REPORT",
        'appId': fb.appId,
        'cognitoId': cred.id,
        'reportId': report.id
      }..addAll(info);

      var text = JSON.encode(data);
      text = new Base64Encoder().convert(new AsciiEncoder().convert(text));
      text = Uri.encodeFull(text);
      return "${url}/${text}";
    }

    final params = {
      'fb:explicitly_shared': 'true',
      'message': report.comment ?? "",
      "image[0][url]": await report.photo.original.makeUrl(),
      "image[0][user_generated]": 'true',
      'place': og('spot'),
      fb.objectName: og('catch_report', {
        'appName': fb.appName,
        'objectName': fb.objectName,
        'bucketName': settings.s3Bucket,
        'urlTimeout': fb.imageTimeout,
        'table_catch': "${settings.appName}.CATCH"
      })
    };

    final url = "${fb.hostname}/me/${fb.appName}:${fb.actionName}";
    _logger.fine(() => "Posting to ${url}: ${params}");

    FabricCrashlytics.crash("Before posting");
    final result = await HttpRequest.postFormData("${url}?access_token=${token}", params);
    _logger.fine(() => "Result of posting to facebook: ${result?.responseText}");

    if ((result.status / 100).floor() != 2) throw result.responseText;
    final Map obj = JSON.decode(result.responseText);

    if (!obj.containsKey('id')) throw obj;
    return obj['id'];
  }
}
