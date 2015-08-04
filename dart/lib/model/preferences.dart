library triton_note.model.preferences;

import 'package:logging/logging.dart';

import 'package:triton_note/model/_json_support.dart';
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/util/enums.dart';

final _logger = new Logger('UserPreferences');

abstract class UserPreferences implements JsonSupport {
  Measures measures;

  factory UserPreferences.fromJsonString(String text) => new _UserPreferencesImpl(new Map.from(JSON.decode(text)));
  factory UserPreferences.fromMap(Map data) => new _UserPreferencesImpl(data);
}
class _UserPreferencesImpl extends JsonSupport implements UserPreferences {
  final Map _data;
  final CachedProp<Measures> _measures;

  _UserPreferencesImpl(Map data)
      : _data = data,
        _measures = new CachedProp<Measures>(data, 'measures', (map) => new Measures.fromMap(map));

  Map get asMap => _data;

  Measures get measures => _measures.value;
  set measures(Measures v) => _measures.value = v;
}

abstract class Measures implements JsonSupport {
  LengthUnit length;
  WeightUnit weight;
  TemperatureUnit temperature;

  factory Measures.fromJsonString(String text) => new _MeasuresImpl(new Map.from(JSON.decode(text)));
  factory Measures.fromMap(Map data) => new _MeasuresImpl(data);
}
class _MeasuresImpl extends JsonSupport implements Measures {
  final Map _data;
  final CachedProp<TemperatureUnit> _temperature;
  final CachedProp<WeightUnit> _weight;
  final CachedProp<LengthUnit> _length;

  _MeasuresImpl(Map data)
      : _data = data,
        _temperature = new CachedProp<TemperatureUnit>(
            data, 'temperature', (map) => enumByName(TemperatureUnit.values, map), (v) => nameOfEnum(v)),
        _weight = new CachedProp<WeightUnit>(
            data, 'weight', (map) => enumByName(WeightUnit.values, map), (v) => nameOfEnum(v)),
        _length = new CachedProp<LengthUnit>(
            data, 'length', (map) => enumByName(LengthUnit.values, map), (v) => nameOfEnum(v));

  Map get asMap => _data;

  TemperatureUnit get temperature => _temperature.value;
  set temperature(TemperatureUnit v) => _temperature.value = v;

  WeightUnit get weight => _weight.value;
  set weight(WeightUnit v) => _weight.value = v;

  LengthUnit get length => _length.value;
  set length(LengthUnit v) => _length.value = v;
}
