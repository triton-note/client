library triton_note.service.aws.cognito;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js';

import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

import 'package:triton_note/util/fabric.dart';
import 'package:triton_note/service/facebook.dart';

final _logger = new Logger('Cognito');

String _stringify(JsObject obj) => context['JSON'].callMethod('stringify', [obj]);
Map _jsmap(JsObject obj) => obj == null ? {} : JSON.decode(_stringify(obj));

Future<String> get cognitoId async => (await CognitoIdentity.credential).id;

class CognitoSettings {
  static CognitoSettings _instance = null;
  static Future<CognitoSettings> get value async {
    if (_instance == null) {
      Map map = loadYaml(await HttpRequest.getString("settings.yaml"));
      _instance = new CognitoSettings(map['awsRegion'], map['cognitoPoolId'], map['s3Bucket']);
    }
    return _instance;
  }

  final String region, poolId, s3Bucket;
  CognitoSettings(this.region, this.poolId, this.s3Bucket);
}

class CognitoIdentity {
  static JsObject get _credentials => context['AWS']['config']['credentials'];
  static set _credentials(JsObject obj) => context['AWS']['config']['credentials'] = obj;

  static Completer<CognitoIdentity> _onCredential = null;
  static Future<CognitoIdentity> get credential async {
    await _initialize();
    return _onCredential.future;
  }

  static Completer<Null> _onInitialize = null;
  static Future<Null> _initialize() async {
    if (_onInitialize == null) {
      _onInitialize = new Completer();
      try {
        _logger.fine("Initializing Cognito ...");
        final settings = await CognitoSettings.value;

        context['AWS']['config']['region'] = settings.region;
        _credentials = new JsObject(context['AWS']['CognitoIdentityCredentials'], [
          new JsObject.jsify({'IdentityPoolId': settings.poolId})
        ]);

        if (_ConnectedServices.get(PROVIDER_KEY_FACEBOOK)) {
          await FBConnect.login();
        } else {
          await _refresh();
          FabricAnswers.eventLogin(method: "Cognito");
        }
        _onInitialize.complete();
      } catch (ex) {
        _logger.warning("Error on initializing: ${ex}");
        _onInitialize.completeError(ex);
      }
    }
    return _onInitialize.future;
  }

  static Future<Null> _setToken(String service, String token) async {
    _logger.fine("SignIn: ${service}");

    final logins = _jsmap(_credentials['params']['Logins']);

    if (!logins.containsKey(service)) {
      logins[service] = token;
      await _refresh(() {
        _logger.finest(() => "Added token: ${service}");
        _credentials['params']['Logins'] = new JsObject.jsify(logins);
      });
      FabricAnswers.eventLogin(method: service);
      _ConnectedServices.set(service, true);
    } else {
      _logger.warning(() => "Nothing to do, since already joined: ${service}");
    }
  }

  static Future<Null> _removeToken(String service) async {
    _logger.fine("SignOut: ${service}");

    final Map logins = _jsmap(_credentials['params']['Logins']);

    if (logins.containsKey(service)) {
      logins.remove(service);
      await _refresh(() {
        _logger.finest(() => "Removed token: ${service}");
        _credentials['params']['Logins'] = new JsObject.jsify(logins);
      });
      _ConnectedServices.set(service, false);
    } else {
      _logger.warning(() => "Nothing to do, since not joined: ${service}");
    }
  }

  static Future<Null> _refresh([void proc()]) async {
    final old = !(_onInitialize?.isCompleted ?? false) ? null : await credential;
    final hooks = (old == null) ? null : new List.unmodifiable(_changingHooks);

    _onCredential = new Completer();

    if (proc != null) proc();
    _credentials['params']['IdentityId'] = null;
    _credentials['expired'] = true;

    _logger.fine("Getting credentials");
    _credentials.callMethod('get', [
      (error) async {
        if (error == null) {
          final cred = new CognitoIdentity();

          if (hooks != null && old.id != cred.id) {
            _logger.fine(() => "Starting hooks on changing coginito id: ${old.id} -> ${cred.id}");
            await Future.wait(hooks.map((hook) {
              try {
                return hook(old.id, cred.id);
              } catch (ex) {
                FabricCrashlytics.crash("Fatal Error: _cognitoIdChanged: ${ex}");
              }
            }));
          }
          _onCredential.complete(cred);
        } else {
          _logger.fine("Cognito Error: ${error}");
          _onCredential.completeError(error);
        }
      }
    ]);
    await _onCredential.future;
  }

  static Future<Null> joinFacebook(String token) async => _setToken(PROVIDER_KEY_FACEBOOK, token);
  static Future<Null> dropFacebook() async => _removeToken(PROVIDER_KEY_FACEBOOK);

  static final String PROVIDER_KEY_FACEBOOK = 'graph.facebook.com';

  static List<CognitoIdChangingHook> _changingHooks = [];
  static void addChaningHook(CognitoIdChangingHook hook) => _changingHooks.add(hook);

  ////////////////
  // In instance

  final String id;
  final Map<String, String> logins;

  CognitoIdentity()
      : this.id = _credentials['identityId'],
        this.logins = new Map.unmodifiable(_jsmap(_credentials['params']['Logins'])) {
    _logger.finer(() => "CognitoIdentity(${id}) [${logins.keys.join(', ')}]");
    assert(id != null);
  }

  bool hasFacebook() => logins.containsKey(PROVIDER_KEY_FACEBOOK);
}

typedef Future CognitoIdChangingHook(String oldId, String newId);

class _ConnectedServices {
  static Map<String, bool> get _value => JSON.decode(window.localStorage['cognito'] ?? '{}');
  static set _value(Map<String, bool> v) => window.localStorage['cognito'] = JSON.encode(v ?? {});

  static bool get(String service) => _value[service] ?? false;
  static set(String service, bool v) => _value = _value..[service] = v;
}

class CognitoSync {
  static final _logger = new Logger('CognitoSync');

  static Future<JsObject> get _client async {
    await CognitoIdentity.credential;
    return new JsObject(context['AWS']['CognitoSyncManager'], []);
  }

  static Future<JsObject> _invoke(JsObject target, String methodName, List params) async {
    final result = new Completer();
    try {
      target.callMethod(
          methodName,
          params
            ..add((error, data) {
              if (error != null) {
                _logger.warning("Error on '${methodName}': ${error}");
                result.completeError(error);
              } else {
                _logger.finest(() => "Result of '${methodName}': ${data}");
                result.complete(data);
              }
            }));
    } catch (ex) {
      result.completeError(ex);
    }
    return result.future;
  }

  static Future<CognitoSync> getDataset(String name) async {
    final dataset = await _invoke(await _client, 'openOrCreateDataset', [name]);
    return new CognitoSync(dataset);
  }

  static const refreshDur = const Duration(seconds: 60);

  final JsObject _dataset;
  CognitoSync(this._dataset);

  Timer _refreshTimer;

  Future<String> get(String key) async {
    final data = await _invoke(_dataset, 'get', [key]);
    return data as String;
  }

  Future<Null> put(String key, String value) async {
    await _invoke(_dataset, 'put', [key, value]);
    if (_refreshTimer != null && _refreshTimer.isActive) _refreshTimer.cancel();
    _refreshTimer = new Timer(refreshDur, synchronize);
  }

  Future<Null> synchronize() async {
    final result = new Completer();
    _dataset.callMethod('synchronize', [
      new JsObject.jsify({
        'onSuccess': (dataset, newRecords) {
          _logger.finest(() => "[synchronize] onSuccess: ${dataset}, ${newRecords}");
          result.complete();
        },
        'onFailure': (error) {
          _logger.finest(() => "[synchronize] onFailure: ${error}");
          result.complete();
        },
        'onConflict': (dataset, conflicts, callback) {
          _logger.finest(() => "[synchronize] onConflict: ${dataset}, ${conflicts}, ${callback}");
          final resolved = conflicts.map((c) => c.callMethod('resolveWithRemoteRecord', []));
          dataset.callMethod('resolve', [
            new JsObject.jsify(resolved),
            () {
              result.complete();
              return (callback == null) ? null : callback.callMethod('call', [true]);
            }
          ]);
        },
        'onDatasetDeleted': (dataset, datasetName, callback) {
          _logger.finest(() => "[synchronize] onDatasetDeleted: ${dataset}, ${datasetName}, ${callback}");
          result.complete();
          // This does not work. see: https://forums.aws.amazon.com/thread.jspa?threadID=178748
          // return callback.callMethod('call', [false]);
        },
        'onDatasetMerged': (dataset, datasetNames, callback) {
          _logger.finest(() => "[synchronize] onDatasetMerged: ${dataset}, ${datasetNames}, ${callback}");
          result.complete();
          return callback.callMethod('call', [true]);
        }
      })
    ]);
    return result.future;
  }
}
