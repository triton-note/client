library triton_note.service.preferences;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/aws/cognito.dart';
import 'package:triton_note/util/enums.dart';

final _logger = new Logger('UserPreferences');

class UserPreferences {
  static const DATASET_MEASURES = 'Measures';

  static Completer<UserPreferences> _onCurrent;
  static Future<UserPreferences> get current async {
    if (_onCurrent == null) {
      _onCurrent = new Completer();
      final dataset = await CognitoSync.getDataset(DATASET_MEASURES);
      await dataset.synchronize();
      _onCurrent.complete(new UserPreferences(new _MeasuresImpl(dataset)));
    }
    return _onCurrent.future;
  }

  final Measures measures;

  UserPreferences(this.measures);
}

abstract class Measures {
  LengthUnit length;
  WeightUnit weight;
  TemperatureUnit temperature;
}

class _MeasuresImpl implements Measures {
  static const KEY_LENGTH = 'length';
  static const KEY_WEIGHT = 'weight';
  static const KEY_TEMPERATURE = 'temperature';

  final CognitoSync _dataset;

  String _length, _weight, _temperature;

  _MeasuresImpl(this._dataset) {
    _init();
  }
  _init() async {
    _length = await _dataset.get(KEY_LENGTH);
    if (_length == null) length = LengthUnit.cm;
    _weight = await _dataset.get(KEY_WEIGHT);
    if (_weight == null) weight = WeightUnit.g;
    _temperature = await _dataset.get(KEY_TEMPERATURE);
    if (_temperature == null) temperature = TemperatureUnit.Cels;
  }

  LengthUnit get length => enumByName(LengthUnit.values, _length);
  void set length(LengthUnit v) {
    _length = nameOfEnum(v);
    _dataset.put(KEY_LENGTH, _length);
  }

  WeightUnit get weight => enumByName(WeightUnit.values, _weight);
  void set weight(WeightUnit v) {
    _weight = nameOfEnum(v);
    _dataset.put(KEY_WEIGHT, _weight);
  }

  TemperatureUnit get temperature => enumByName(TemperatureUnit.values, _temperature);
  void set temperature(TemperatureUnit v) {
    _temperature = nameOfEnum(v);
    _dataset.put(KEY_TEMPERATURE, _temperature);
  }
}
