library settings;

import 'dart:async';
import 'dart:html';
import 'package:yaml/yaml.dart';

class Settings {
  static Map<String, String> _map;

  /**
   * This method will be invoked automatically.
   * But you can invoke manually to setup your own map of test.
   * 
   * @param onFail works only on failed to get settings
   */
  static Future<Map<String, String>> initialize([Map<String, String> onFail = null]) async {
    try {
      final text = await HttpRequest.getString("settings.yaml");
      _map = loadYaml(text);
    } catch (ex) {
      _map = onFail;
    }
    return _map;
  }

  static Future<String> _get(String name) async {
    if (_map == null) {
      await initialize();
    }
    return _map == null ? null : _map[name];
  }
  static Future<String> get awsRegion => _get('awsRegion');
  static Future<String> get cognitoId => _get('cognitoId');
  static Future<String> get s3Bucket => _get('s3Bucket');
  static Future<String> get serverUrl => _get('serverUrl');
}
