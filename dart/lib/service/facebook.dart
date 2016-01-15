library triton_note.service.facebook;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js';

import 'package:logging/logging.dart';

import 'package:triton_note/formatter/fish_formatter.dart';
import 'package:triton_note/settings.dart';
import 'package:triton_note/service/aws/cognito.dart';
import 'package:triton_note/model/report.dart';
import 'package:triton_note/util/cordova.dart';

class FBConnect {
  static final Logger _logger = new Logger('FBConnect');

  static Future _call(String name, List args) {
    if (!isCordova) return _FBJSSDK.call(name, args);

    final completer = new Completer();
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
    await CognitoIdentity.joinFacebook(token);
    return token;
  }

  static Future<Null> logout() async {
    await _call('logout', []);
    await CognitoIdentity.dropFacebook();
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

  static String generateMessage(Report report) {
    final array = [report.comment ?? "", ""];
    final formatter = new FishFormatter();
    array.addAll(report.fishes.map(formatter.call));
    return array.join("\n").trim();
  }

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
      'message': generateMessage(report),
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

    final result = await HttpRequest.postFormData("${url}?access_token=${token}", params);
    _logger.fine(() => "Result of posting to facebook: ${result?.responseText}");

    if ((result.status / 100).floor() != 2) throw result.responseText;
    final Map obj = JSON.decode(result.responseText);

    if (!obj.containsKey('id')) throw obj;
    return (report.published ??= new Published.fromMap({})).facebook = obj['id'];
  }

  static Future<Map> getAction(String id) async {
    if (id == null) return null;

    final ac = await FBConnect.getToken();
    if (ac == null) return null;

    final fb = await _FBSettings.load();

    final url = "${fb.hostname}/${id}?access_token=${ac['token']}";
    final result = await HttpRequest.request(url);
    _logger.fine(() => "Result of quering action info: ${result?.responseText}");

    if ((result.status / 100).floor() != 2) throw result.responseText;
    final Map obj = JSON.decode(result.responseText);

    return obj.containsKey('id') ? obj : null;
  }
}

class _FBJSSDK {
  static final Logger _logger = new Logger('FBJSSDK');

  static Future<Null> _init() async {
    final id = 'facebook-jssdk';
    if (document.getElementById(id) != null) return null;

    final completer = new Completer();
    try {
      final appId = (await HttpRequest.getString(".facebook_app_id")).trim();
      _logger.finest(() => "Setting browser facebook app id: ${appId}");

      context['fbAsyncInit'] = () async {
        context['FB'].callMethod('init', [
          new JsObject.jsify({'appId': appId, 'xfbml': false, 'version': 'v2.5'})
        ]);
        _logger.finest(() => "FB initialized.");
        completer.complete();
      };
      final js = new ScriptElement()
        ..id = id
        ..src = "//connect.facebook.net/en_US/sdk.js";
      final fjs = document.getElementsByTagName('script')[0];
      _logger.finest(() => "Appending Facebook SDK");
      fjs.parentNode.insertBefore(js, fjs);
    } catch (ex) {
      completer.completeError(ex);
    }
    return completer.future;
  }

  static Future call(String name, List args) async {
    await _init();

    switch (name) {
      case 'login':
        return await _login(args);
      case 'logout':
        return await _logout();
    }
  }

  static Future _invoke(String name, [List perms = null]) async {
    final completer = new Completer();
    try {
      final args = perms == null ? [] : perms;
      args.insert(0, (response) {
        _logger.finest(() => "Response: ${response}");
        completer.complete(response);
      });
      _logger.finest(() => "Invoking FB.${name}(${args})");
      context['FB'].callMethod(name, args);
    } catch (ex) {
      completer.completeError(ex);
    }
    return completer.future;
  }

  static _login(List<String> perms) async {
    if (perms.isEmpty) perms.add('public_profile');

    final res = await _invoke('login', [
      new JsObject.jsify({'scope': perms.join(',')})
    ]);
    if (res['status'] == 'connected') {
      return res['authResponse']['accessToken'];
    } else {
      return null;
    }
  }

  static _logout() async {
    await _invoke('logout');
  }
}
