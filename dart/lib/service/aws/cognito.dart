library triton_note.service.aws.cognito;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

import 'package:triton_note/util/getter_setter.dart';

final _logger = new Logger('Cognito');

String _stringify(JsObject obj) => context['JSON'].callMethod('stringify', [obj]);

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
  static Future<CognitoIdentity> get credential async {
    await _initialize();

    final credId = context['AWS']['config']['credentials']['identityId'];
    final logins = context['AWS']['config']['credentials']['params']['Logins'];

    _logger.finer(() => "CognitoIdentity(${_stringify(credId)}):${_stringify(logins)}");
    return new CognitoIdentity(credId, logins);
  }

  static Completer _onInitialize = null;
  static _initialize() async {
    if (_onInitialize == null) {
      _onInitialize = new Completer();
      try {
        _logger.fine("Initializing Cognito ...");
        final settings = await CognitoSettings.value;

        context['AWS']['config']['region'] = settings.region;
        final creds = new JsObject(context['AWS']['CognitoIdentityCredentials'], [
          new JsObject.jsify({'IdentityPoolId': settings.poolId})
        ]);
        context['AWS']['config']['credentials'] = creds;

        try {
          await _refresh();
        } catch (ex) {
          _logger.fine("Initialize error (reset and try again): ${ex}");
          creds['params']['IdentityId'] = null;
          await _refresh();
        }
        context['plugin']['Fabric']['Answers'].callMethod('eventLogin', [
          new JsObject.jsify({"method": "Cognito"})
        ]);
        _onInitialize.complete();
      } catch (ex) {
        _logger.warning("Error on initializing: ${ex}");
        _onInitialize.completeError(ex);
      }
    }
    return _onInitialize.future;
  }

  static Future<CognitoIdentity> _setToken(String service, String token) async {
    _logger.fine("Google Signin Token: ${token}");

    final creds = context['AWS']['config']['credentials'];
    final logins = (creds['params']['Logins'] == null) ? {} : creds['params']['Logins'];
    logins[service] = token;
    creds['params']['Logins'] = new JsObject.jsify(logins);
    creds['expired'] = true;

    await _refresh();
    return await credential;
  }

  static Future<Null> _refresh() async {
    final result = new Completer();

    final creds = context['AWS']['config']['credentials'];
    _logger.fine("Getting credentials");
    creds.callMethod('get', [
      (error) {
        if (error == null) {
          result.complete();
        } else {
          _logger.fine("Cognito Error: ${error}");
          result.completeError(error);
        }
      }
    ]);

    return result.future;
  }

  final String id;
  final Map<String, String> logins;

  CognitoIdentity(this.id, Map logins) : this.logins = logins == null ? const {} : new Map.unmodifiable(logins);
}

class CognitoSync {
  static final Getter<Future<JsObject>> _client = new Getter(() async {
    await CognitoIdentity.credential;
    return new JsObject(context['AWS']['CognitoSyncManager'], []);
  });

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
    final dataset = await _invoke(await _client.value, 'openOrCreateDataset', [name]);
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
