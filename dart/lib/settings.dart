library triton_note.settings;

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

import 'package:triton_note/service/aws/cognito.dart';
import 'package:triton_note/service/aws/s3file.dart';
import 'package:triton_note/service/aws/sns.dart';
import 'package:triton_note/util/cordova.dart';

final Logger _logger = new Logger('Settings');

Completer<_Settings> _initializing;
/**
 * This method will be invoked automatically.
 * But you can invoke manually to setup your own map of test.
 *
 * @param onFail works only on failed to get settings
 */
Future<_Settings> _initialize() async {
  if (_initializing == null) {
    _initializing = new Completer();
    try {
      final local = await CognitoSettings.value;
      final server = loadYaml(await S3File.read('unauthorized/client.yaml', local.s3Bucket));
      final map = new Map.from(server);
      _logger.config("Initializing...");
      _initializing.complete(new _Settings(local, map));
      SNS.init();
    } catch (ex) {
      _logger.warning("Failed to read settings file: ${ex}");
      _initializing.completeError(ex);
    }
  }
  return _initializing.future;
}

Future<_Settings> get Settings => _initialize();

Future<Map> get AuthorizedSettings async {
  final Map settings = loadYaml(await S3File.read('authorized/settings.yaml', (await Settings).s3Bucket));
  _logger.config(() => "Authorized settings loaded");
  return settings;
}

class _Settings {
  _Settings(this._local, this._map);
  final CognitoSettings _local;
  final Map _map;

  String get awsRegion => _local.region;
  String get s3Bucket => _local.s3Bucket;
  String get cognitoPoolId => _local.poolId;

  String get appName => _map['appName'];
  String get googleProjectNumber => _map['googleProjectNumber'];
  String get googleKey => _map['googleBrowserKey'];
  String get snsPlatformArn => _map['snsPlatformArn'][isAndroid ? 'google' : 'apple'];

  _Photo _photo;
  _Photo get photo {
    if (_photo == null) _photo = new _Photo(_map['photo']);
    return _photo;
  }

  _ServerApiMap _server;
  _ServerApiMap get server {
    if (_server == null) _server = new _ServerApiMap(_map['api']);
    return _server;
  }
}

class _Photo {
  _Photo(this._map);
  final Map _map;

  Duration get urlTimeout => new Duration(seconds: _map['urlTimeout']);
}

class _ServerApiMap {
  static _api(Map config, String name) => new ApiInfo("${config['base_url']}/${config['gateways'][name]}",
      config['key'], config['retry_limit'], config['retry_duration']);

  final ApiInfo moon, weather, cognitoIdChanged;

  _ServerApiMap(Map map)
      : moon = _api(map, 'moon'),
        weather = _api(map, 'weather'),
        cognitoIdChanged = _api(map, 'cognitoIdChanged');
}

class ApiInfo {
  final String url;
  final String key;
  final int retryLimit;
  final Duration retryDur;

  ApiInfo(this.url, this.key, this.retryLimit, int dur) : retryDur = new Duration(milliseconds: dur);
}
