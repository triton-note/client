library triton_note.settings;

import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

import 'package:triton_note/service/aws/s3file.dart';
import 'package:triton_note/util/cordova.dart';

final _logger = new Logger('Settings');

Completer<_Settings> _initializing;
/**
 * This method will be invoked automatically.
 * But you can invoke manually to setup your own map of test.
 *
 * @param onFail works only on failed to get settings
 */
Future<_Settings> _initialize([Map<String, String> onFail = null]) async {
  if (_initializing == null) {
    _initializing = new Completer();
    try {
      Map read(String text) {
        _logger.finest(() => "Reading YAML: ${text}");
        return loadYaml(text);
      }
      final local = read(await HttpRequest.getString("settings.yaml"));
      final server = read(
          await S3File.read('unauthorized/client.yaml', local['s3Bucket'], local['accessKey'], local['secretKey']));
      final map = new Map.from(server);
      _logger.config("using: ${map}");
      _initializing.complete(new _Settings(map));
    } catch (ex) {
      final local = (onFail != null) ? new Map.unmodifiable(onFail) : const {};
      _logger.warning("Failed to get yaml file: ${ex}, using: ${local}");
      _initializing.complete(new _Settings(local));
    }
  }
  return _initializing.future;
}

Future<_Settings> get Settings => _initialize();

class _Settings {
  _Settings(this._map);
  final Map _map;

  String get appName => _map['appName'];
  String get awsRegion => _map['awsRegion'];
  String get cognitoPoolId => _map['cognitoPoolId'];
  String get s3Bucket => _map['s3Bucket'];
  String get googleKey => _map['googleBrowserKey'];
  String get googleProjectNumber => _map['googleProjectNumber'];
  String get platformArn => _map['platformArn'][isAndroid ? 'google' : 'apple'];

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
  _ServerApiMap(this._map);
  final Map _map;

  _api(String name) => new ApiInfo("${_map['base_url']}/${_map['gateways'][name]}", _map['key']);

  ApiInfo get moon => _api('moon');
  ApiInfo get weather => _api('weather');
}

class ApiInfo {
  final String url;
  final String key;

  ApiInfo(this.url, this.key);
}
