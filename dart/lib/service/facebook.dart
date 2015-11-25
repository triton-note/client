library triton_note.service.facebook;

import 'dart:async';
import 'dart:convert';
import 'dart:js';

import 'package:logging/logging.dart';

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

  static Future<String> login() => _call('login', []);
  static Future<String> grantPublish() => _call('login', ['publish_actions']);
  static Future<String> getName() => _call('getName', []);
  static Future<Map> getToken() => _call('getToken', []);
  static Future logout() => _call('logout', []);
}

class FBPublish {
  static final _logger = new Logger('FBPublish');
}
