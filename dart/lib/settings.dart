library triton_note.settings;

import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

import 'package:triton_note/service/aws/s3file.dart';

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
          await S3File.read('unauthorized/settings.yaml', local['s3Bucket'], local['accessKey'], local['secretKey']));
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

  _Photo _photo;
  _Photo get photo {
    if (_photo == null) _photo = new _Photo(_map['photo']);
    return _photo;
  }
  _Facebook _facebook;
  _Facebook get facebook {
    if (_facebook == null) _facebook = new _Facebook(_map['facebook']);
    return _facebook;
  }
  _OpenWeatherMap _openweathermap;
  _OpenWeatherMap get openweathermap {
    if (_openweathermap == null) _openweathermap = new _OpenWeatherMap(_map['openweathermap']);
    return _openweathermap;
  }
  _LambdaMap _lambda;
  _LambdaMap get lambda {
    if (_lambda == null) _lambda = new _LambdaMap(_map['lambda']);
    return _lambda;
  }
}

class _Photo {
  _Photo(this._map);
  final Map _map;

  Duration get urlTimeout => new Duration(seconds: _map['urlTimeout']);
  int get mainviewSize => _map['mainviewSize'];
  int get thumbnailSize => _map['thumbnailSize'];
}

class _Facebook {
  _Facebook(this._map);
  final Map _map;

  String get host => _map['host'];
  String get appName => _map['appName'];
  String get appId => _map['appId'];
  Duration get imageTimeout => new Duration(seconds: _map['imageTimeout']);
  String get actionName => _map['actionName'];
  String get objectName => _map['objectName'];
}

class _OpenWeatherMap {
  _OpenWeatherMap(this._map);
  final Map _map;

  String get url => _map['url'];
  String get apiKey => _map['apiKey'];
  String get iconUrl => _map['iconUrl'];
}

class _LambdaMap {
  _LambdaMap(this._map);
  final Map _map;

  _Lambda get moon => new _Lambda(_map['moon']);
}
class _Lambda {
  _Lambda(this._map);
  final Map _map;

  String get url => _map['url'];
  String get key => _map['key'];
}
