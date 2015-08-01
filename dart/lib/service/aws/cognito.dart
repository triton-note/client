library triton_note.service.aws.cognito;

import 'dart:async';
import 'dart:collection';
import 'dart:js';

import 'package:logging/logging.dart';

import 'package:triton_note/util/cordova.dart';
import 'package:triton_note/settings.dart';

final _logger = new Logger('Cognito');

String _stringify(JsObject obj) => context['JSON'].callMethod('stringify', [obj]);

class Identity {
  final String id;
  final Map<String, String> logins;

  Identity(this.id, this.logins);
}

class Cognito {
  static final Future<bool> initialized = Cognito._initialize();

  static final Completer<String> _connected = new Completer<String>();
  static bool get isConnected => _connected.isCompleted;
  static void onConnected(void proc(String)) {
    _connected.future.then(proc);
  }

  static Future<Identity> get identity =>
      initialized.then((v) => !v ? null : new Identity(Cognito.identityId, Cognito.logins));

  static Future<bool> _initialize() async {
    _logger.fine("Initializing Cognito ...");

    final awsRegion = await Settings.awsRegion;
    final cognitoPoolId = await Settings.cognitoPoolId;

    context['AWS']['config']['region'] = awsRegion;
    final creds = new JsObject(
        context['AWS']['CognitoIdentityCredentials'], [new JsObject.jsify({'IdentityPoolId': cognitoPoolId})]);
    context['AWS']['config']['credentials'] = creds;

    try {
      return await _refresh();
    } catch (ex) {
      _logger.fine("Initialize error: ${ex}");
      creds['params']['IdentityId'] = null;
      return _refresh();
    } finally {
      hideSplashScreen();
    }
  }

  static String get identityId => context['AWS']['config']['credentials']['identityId'];
  static Map<String, String> get logins {
    final result = {};
    final map = context['AWS']['config']['credentials']['params']['Logins'];
    if (map is Map) map.forEach((key, value) {
      result[key] = value;
    });
    return new UnmodifiableMapView(result);
  }

  static Future<bool> _setToken(String service, String token) async {
    _logger.fine("Google Signin Token: ${token}");

    final creds = context['AWS']['config']['credentials'];
    final logins = (creds['params']['Logins'] == null) ? {} : creds['params']['Logins'];
    logins[service] = token;
    creds['params']['Logins'] = new JsObject.jsify(logins);
    creds['expired'] = true;

    final done = await _refresh();
    if (done) _connected.complete(identityId);
    return done;
  }

  static Future<bool> _refresh() async {
    final result = new Completer();

    final creds = context['AWS']['config']['credentials'];
    _logger.fine("Getting credentials");
    creds.callMethod('get', [
      (error) {
        if (error == null) {
          result.complete(true);
        } else {
          _logger.fine("Cognito Error: ${error}");
          result.completeError(error);
        }
      }
    ]);

    return result.future;
  }
}
