library triton_note.service.preferences;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/aws/cognito.dart';
import 'package:triton_note/util/enums.dart';
import 'package:triton_note/util/fabric.dart';

final _logger = new Logger('UserPreferences');

class UserPreferences {
  static const DATASET_MEASURES = 'Measures';

  static Completer<UserPreferences> _onCurrent;
  static Future<UserPreferences> get current async {
    if (_onCurrent == null) {
      _onCurrent = new Completer();
      final dataset = await CognitoSync.getDataset(DATASET_MEASURES);
      await dataset.synchronize();
      final m = new _MeasuresImpl(dataset);
      await m.loaded;
      _onCurrent.complete(new UserPreferences(m));
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
  final Completer _onLoaded = new Completer();
  Future get loaded => _onLoaded.future;

  String _length, _weight, _temperature;

  _MeasuresImpl(this._dataset) {
    _init();
    CognitoIdentity.addChaningHook(_cognitoIdChanged);
  }

  toString() => "Measures(${KEY_LENGTH}: ${length}, ${KEY_WEIGHT}: ${weight}, ${KEY_TEMPERATURE}: ${temperature})";

  _init() async {
    try {
      await _loadAll();
      _onLoaded.complete();
    } catch (ex) {
      _onLoaded.completeError(ex);
    }
  }

  _loadAll() async {
    _length = await _dataset.get(KEY_LENGTH);
    if (_length == null) length = LengthUnit.cm;
    _weight = await _dataset.get(KEY_WEIGHT);
    if (_weight == null) weight = WeightUnit.g;
    _temperature = await _dataset.get(KEY_TEMPERATURE);
    if (_temperature == null) temperature = TemperatureUnit.Cels;

    _logger.finest(() => "Loaded: ${this}");
  }

  Future _cognitoIdChanged(String oldId, String newId) async {
    try {
      _logger.finest(() => "[${this}] Finishing changing cognito id: ${oldId} -> ${newId}");
      await _dataset.synchronize();
      await _loadAll();
    } catch (ex) {
      FabricCrashlytics.crash("[${this}] Fatal Error: _cognitoIdChanged: ${ex}");
    }
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
