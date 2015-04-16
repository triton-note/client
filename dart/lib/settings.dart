library settings;

import 'dart:async';
import 'dart:html';
import 'package:yaml/yaml.dart';

class Settings {
  static Future<Map<String, String>> _map;

  static initialize() {
    _map = HttpRequest.getString("settings.yaml").then((text) {
      return loadYaml(text);
    });
  }

  static Future<String> _get(String name) => _map.then((a) => a[name]);

  static Future<String> get awsRegion => _get('awsRegion');
  static Future<String> get cognitoId => _get('cognitoId');
  static Future<String> get s3Bucket => _get('s3Bucket');
}
