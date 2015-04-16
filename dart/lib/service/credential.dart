library credential;

import 'dart:async';
import 'dart:js';

import 'package:triton_note/util/cordova.dart';
import 'package:triton_note/util/after_done.dart';
import 'package:triton_note/settings.dart';

String _stringify(JsObject obj) => context['JSON'].callMethod('stringify', [obj]);

class Credential {
  static final initialized = _Cognito._initialize();

  static final AfterDone<String> _connected = new AfterDone<String>("Credential connected");
  static void onConnected(void proc(String)) => _connected.listen(proc);
  static bool get isConnected => _connected.isDone;

  static Future<String> get identityId => initialized.then((v) => !v ? null : _Cognito.identityId);

  static Future<bool> googleSignIn(bool immediate) => initialized.then((v) => !v ? null : _GoogleSignIn.signin(immediate));
}

class _Cognito {
  static Future<bool> _initialize() async {
    print("Initializing Cognito ...");

    final awsRegion = await Settings.awsRegion;
    final cognitoId = await Settings.cognitoId;

    context['AWS']['config']['region'] = awsRegion;
    final creds = new JsObject(context['AWS']['CognitoIdentityCredentials'], [new JsObject.jsify({'IdentityPoolId': cognitoId})]);
    context['AWS']['config']['credentials'] = creds;

    try {
      return await _refresh();
    } catch (ex) {
      print("Initialize error: ${ex}");
      creds['params']['IdentityId'] = null;
      return _refresh();
    }
  }

  static String get identityId => context['AWS']['config']['credentials']['identityId'];

  static Future<bool> _setToken(String service, String token) async {
    print("Google Signin Token: ${token}");

    final creds = context['AWS']['config']['credentials'];
    final logins = (creds['params']['Logins'] == null) ? {} : creds['params']['Logins'];
    logins[service] = token;
    creds['params']['Logins'] = new JsObject.jsify(logins);
    creds['expired'] = true;

    final done = await _refresh();
    if (done) Credential._connected.done(identityId);
    return done;
  }

  static Future<bool> _refresh() async {
    final result = new Completer();

    final creds = context['AWS']['config']['credentials'];
    print("Getting credentials");
    creds.callMethod('get', [
      (error) {
        if (error == null) {
          result.complete(true);
        } else {
          print("Cognito Error: ${error}");
          result.completeError(error);
        }
      }
    ]);

    return result.future;
  }
}

class _GoogleSignIn {
  static const googleApiKey = "AIzaSyAceAj4hCRXQKofpZKAd8Zo0nx5wYuT220";
  static const googleClientId = "945048561360-rbftrc4m2965vuqdhr0s2nuhjvvjkbg1.apps.googleusercontent.com";
  static const scopes = const ["https://www.googleapis.com/auth/plus.login"];

  static Future<bool> signin(bool immediate) async {
    Future<bool> _onBrowser() async {
      final token = await _auth(immediate);
      final userId = await _getUserId();
      return (userId == null) ? false : _Cognito._setToken('accounts.google.com', token);
    }
    Future<bool> _onCordova() {
      // TODO Implement Google SignIn on Cordova
      final result = new Completer();
      new Timer(new Duration(seconds: 3), () {
        result.complete(true);
      });
      return result.future;
    }
    return Cordova.isCordova ? _onCordova() : _onBrowser();
  }

  static Future<JsObject> _request(String path) {
    final result = new Completer();
    context['gapi']['client'].callMethod('request', [new JsObject.jsify({'path': path})]).callMethod('then', [
      (res) {
        result.complete(res['result']);
      },
      (error) {
        result.completeError(error.result.error.message);
      }
    ]);
    return result.future;
  }

  static Future<String> _getUserId() async {
    final result = await _request('/plus/v1/people/me');
    print("me: ${_stringify(result)}");
    return result['id'];
  }

  static Future<String> _auth(bool immediate) {
    final result = new Completer();
    context['gapi']['client'].callMethod('setApiKey', [googleApiKey]);
    context['gapi']['auth'].callMethod('authorize', [
      new JsObject.jsify({'client_id': googleClientId, 'scope': scopes.join(' '), 'response_type': 'token id_token', 'immediate': immediate}),
      (res) {
        if (res['error'] != null) {
          result.completeError("Google Signin Error: ${res['error']}");
        } else {
          result.complete(res['id_token']);
        }
      },
      (error) {
        result.completeError(error.result.error.message);
      }
    ]);
    return result.future;
  }
}
