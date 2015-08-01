library triton_note.service.preferences;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/server.dart';

final _logger = new Logger('UserPreferences');

class UserPreferences {
  static Future<Measures> _measures;
  static Future<Measures> get measures {
    if (_measures == null) _measures = Server.loadMeasures();
    return _measures;
  }

  static update(Measures v) {
    _measures = new Future.value(v);
    Server.updateMeasures(v);
  }
}

/**
 * Future で返されると HTML View で困るので、取得中なら null を返す実装。
 */
class CachedMeasures {
  static Future<LengthUnit> _gettingLength;
  static LengthUnit _lengthUnit;
  static LengthUnit get lengthUnit {
    if (_lengthUnit != null) return _lengthUnit;
    if (_gettingLength == null) {
      _gettingLength = UserPreferences.measures.then((m) => _lengthUnit = m.length);
    }
    return null;
  }

  static Future<WeightUnit> _gettingWeight;
  static WeightUnit _weightUnit;
  static WeightUnit get weightUnit {
    if (_weightUnit != null) return _weightUnit;
    if (_gettingWeight == null) {
      _gettingWeight = UserPreferences.measures.then((m) => _weightUnit = m.weight);
    }
    return null;
  }

  static Future<TemperatureUnit> _gettingTemperature;
  static TemperatureUnit _temperatureUnit;
  static TemperatureUnit get temperatureUnit {
    if (_temperatureUnit != null) return _temperatureUnit;
    if (_gettingTemperature == null) {
      _gettingTemperature = UserPreferences.measures.then((m) => _temperatureUnit = m.temperature);
    }
    return null;
  }
}
