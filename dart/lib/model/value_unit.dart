library triton_note.model.value_unit;

import 'dart:math';

import 'package:logging/logging.dart';

import 'package:triton_note/model/_json_support.dart';
import 'package:triton_note/util/enums.dart';

final _logger = new Logger('ValueUnit');

String round(double v, int digits) {
  if (digits <= 0) return "${v.round()}";
  final d = pow(10, digits);
  return "${(v * d).round() / d}";
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
            data, 'temperature', (o) => enumByName(TemperatureUnit.values, o), (v) => nameOfEnum(v)),
        _weight = new CachedProp<WeightUnit>(
            data, 'weight', (o) => enumByName(WeightUnit.values, o), (v) => nameOfEnum(v)),
        _length = new CachedProp<LengthUnit>(
            data, 'length', (o) => enumByName(LengthUnit.values, o), (v) => nameOfEnum(v));

  Map get asMap => _data;

  TemperatureUnit get temperature => _temperature.value;
  set temperature(TemperatureUnit v) => _temperature.value = v;

  WeightUnit get weight => _weight.value;
  set weight(WeightUnit v) => _weight.value = v;

  LengthUnit get length => _length.value;
  set length(LengthUnit v) => _length.value = v;
}

abstract class ValueUnit<A, U> {
  double value;
  U get unit;
  A convertTo(U dst);
}

abstract class Temperature implements JsonSupport, ValueUnit<Temperature, TemperatureUnit> {
  factory Temperature.fromJsonString(String text) => new _TemperatureImpl(new Map.from(JSON.decode(text)));
  factory Temperature.fromMap(Map data) => new _TemperatureImpl(data);

  factory Temperature.of(TemperatureUnit unit, double value) {
    return new Temperature.fromMap({"unit": nameOfEnum(unit), "value": value});
  }
  factory Temperature.Cels(double value) {
    return new Temperature.of(TemperatureUnit.Cels, value);
  }
  factory Temperature.Fahr(double value) {
    return new Temperature.of(TemperatureUnit.Fahr, value);
  }
}
enum TemperatureUnit { Cels, Fahr }

class _TemperatureImpl extends JsonSupport implements Temperature {
  final Map _data;
  final CachedProp<TemperatureUnit> _unit;

  _TemperatureImpl(Map data)
      : _data = data,
        _unit = new CachedProp<TemperatureUnit>(
            data, 'unit', (o) => enumByName(TemperatureUnit.values, o), (v) => nameOfEnum(v));

  Map get asMap => _data;

  double get value => _data['value'];
  set value(double v) => _data['value'] = v;

  TemperatureUnit get unit => _unit.value;

  Temperature convertTo(TemperatureUnit dst) {
    _logger.finest("Converting ${this.asMap} to '${dst}'");
    if (this.unit == dst) return this;
    else {
      switch (dst) {
        case TemperatureUnit.Cels:
          return new Temperature.Cels((value - 32) * 5 / 9);
        case TemperatureUnit.Fahr:
          return new Temperature.Fahr(value * 9 / 5 + 32);
      }
    }
  }
}

abstract class Weight implements JsonSupport, ValueUnit<Weight, WeightUnit> {
  factory Weight.fromJsonString(String text) => new _WeightImpl(new Map.from(JSON.decode(text)));
  factory Weight.fromMap(Map data) => new _WeightImpl(data);

  factory Weight.of(WeightUnit unit, double value) {
    return new Weight.fromMap({"unit": nameOfEnum(unit), "value": value});
  }
  factory Weight.kg(double value) {
    return new Weight.of(WeightUnit.kg, value);
  }
  factory Weight.pound(double value) {
    return new Weight.of(WeightUnit.pound, value);
  }
}
enum WeightUnit { kg, pound }

class _WeightImpl extends JsonSupport implements Weight {
  static const poundToKg = 0.4536;

  final Map _data;
  final CachedProp<WeightUnit> _unit;

  _WeightImpl(Map data)
      : _data = data,
        _unit = new CachedProp<WeightUnit>(data, 'unit', (o) => enumByName(WeightUnit.values, o), (v) => nameOfEnum(v));

  Map get asMap => _data;

  double get value => _data['value'];
  set value(double v) => _data['value'] = v;

  WeightUnit get unit => _unit.value;

  Weight convertTo(WeightUnit dst) {
    if (this.unit == dst) return this;
    else {
      switch (dst) {
        case WeightUnit.kg:
          return new Weight.kg(value * poundToKg);
        case WeightUnit.pound:
          return new Weight.pound(value / poundToKg);
      }
    }
  }
}

abstract class Length implements JsonSupport, ValueUnit<Length, LengthUnit> {
  factory Length.fromJsonString(String text) => new _LengthImpl(new Map.from(JSON.decode(text)));
  factory Length.fromMap(Map data) => new _LengthImpl(data);

  factory Length.of(LengthUnit unit, double value) {
    return new Length.fromMap({"unit": nameOfEnum(unit), "value": value});
  }
  factory Length.cm(double value) {
    return new Length.of(LengthUnit.cm, value);
  }
  factory Length.inch(double value) {
    return new Length.of(LengthUnit.inch, value);
  }
}

enum LengthUnit { cm, inch }

class _LengthImpl extends JsonSupport implements Length {
  static const inchToCm = 2.54;

  final Map _data;
  final CachedProp<LengthUnit> _unit;

  _LengthImpl(Map data)
      : _data = data,
        _unit = new CachedProp<LengthUnit>(data, 'unit', (o) => enumByName(LengthUnit.values, o), (v) => nameOfEnum(v));

  Map get asMap => _data;

  double get value => _data['value'];
  set value(double v) => _data['value'] = v;

  LengthUnit get unit => _unit.value;

  Length convertTo(LengthUnit dst) {
    if (this.unit == dst) return this;
    else {
      switch (dst) {
        case LengthUnit.cm:
          return new Length.cm(value * inchToCm);
        case LengthUnit.inch:
          return new Length.inch(value / inchToCm);
      }
    }
  }
}
