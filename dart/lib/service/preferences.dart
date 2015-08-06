library triton_note.service.preferences;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/preferences.dart';
import 'package:triton_note/service/aws/dynamodb.dart';

final _logger = new Logger('CachedPreferences');

/**
 * Future で返されると HTML View で困るので、取得中なら null を返す実装。
 */
class CachedPreferences {
  static Future<UserPreferences> _current;
  static Future<UserPreferences> get current {
    if (_current == null) _current = DynamoDB.TABLE_USER.get().then((data) async {
      if (data != null) return new UserPreferences.fromMap(data);
      final content = {'measures': {'temperature': "Cels", 'weight': "g", 'length': "cm"}};
      final map = await DynamoDB.TABLE_USER.put(content, {'id': null});
      return new UserPreferences.fromMap(map);
    });
    return _current;
  }
  static Future<Null> update(UserPreferences v) async {
    if (v != await current) (await current).asMap
      ..clear()
      ..addAll(v.asMap);
    await DynamoDB.TABLE_USER.update(v.asMap);
  }

  static Measures _measures;
  static Measures get measures {
    current.then((c) => _measures = c.measures);
    return _measures;
  }
}
