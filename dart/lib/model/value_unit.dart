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

abstract class ValueUnit<A, U> {
  double value;
  U get unit;
  A convertTo(U dst);

  @override
  bool operator ==(o) => o is A && o.value == value && o.unit == unit;
}

abstract class Temperature extends ValueUnit<Temperature, TemperatureUnit> implements JsonSupport {
  factory Temperature.fromJsonString(String text) => new _TemperatureImpl(new Map.from(JSON.decode(text)));
  factory Temperature.fromMap(Map data) => new _TemperatureImpl(data);

  factory Temperature.of(TemperatureUnit unit, double value) {
    return new Temperature.fromMap({"unit": {'S': nameOfEnum(unit)}, "value": {'N': value}});
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
            data, 'unit', (map) => enumByName(TemperatureUnit.values, map['S']), (v) => {'S': nameOfEnum(v)});

  Map get asMap => _data;

  double get value => double.parse(_data['value']['N']);
  set value(double v) => _data['value']['N'] = v.toString();

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

abstract class Weight extends ValueUnit<Weight, WeightUnit> implements JsonSupport {
  factory Weight.fromJsonString(String text) => new _WeightImpl(new Map.from(JSON.decode(text)));
  factory Weight.fromMap(Map data) => new _WeightImpl(data);

  factory Weight.of(WeightUnit unit, double value) {
    return new Weight.fromMap({"unit": {'S': nameOfEnum(unit)}, "value": {'N': value}});
  }
  factory Weight.kg(double value) {
    return new Weight.of(WeightUnit.kg, value);
  }
  factory Weight.pound(double value) {
    return new Weight.of(WeightUnit.pound, value);
  }
  factory Weight.g(double value) {
    return new Weight.of(WeightUnit.g, value);
  }
  factory Weight.oz(double value) {
    return new Weight.of(WeightUnit.oz, value);
  }
}
enum WeightUnit { kg, g, pound, oz }

class _WeightImpl extends JsonSupport implements Weight {
  static const kg_g = 1000;
  static const pound_oz = 16;
  static const oz_g = 28.349523125;
  static const pound_kg = 0.45359237;

  final Map _data;
  final CachedProp<WeightUnit> _unit;

  _WeightImpl(Map data)
      : _data = data,
        _unit = new CachedProp<WeightUnit>(
            data, 'unit', (map) => enumByName(WeightUnit.values, map['S']), (v) => {'S': nameOfEnum(v)});

  Map get asMap => _data;

  double get value => double.parse(_data['value']['N']);
  set value(double v) => _data['value']['N'] = v.toString();

  WeightUnit get unit => _unit.value;

  Weight convertTo(WeightUnit dst) {
    if (this.unit == dst) return this;
    switch (this.unit) {
      case WeightUnit.kg: // Kg ->
        switch (dst) {
          case WeightUnit.kg:
            return this;
          case WeightUnit.g:
            return new Weight.g(value * kg_g);
          case WeightUnit.oz:
            return new Weight.oz(value * kg_g / oz_g);
          case WeightUnit.pound:
            return new Weight.pound(value / pound_kg);
        }
        break;
      case WeightUnit.g: // g ->
        switch (dst) {
          case WeightUnit.kg:
            return new Weight.kg(value / kg_g);
          case WeightUnit.g:
            return this;
          case WeightUnit.oz:
            return new Weight.oz(value / oz_g);
          case WeightUnit.pound:
            return new Weight.pound(value / kg_g / pound_kg);
        }
        break;
      case WeightUnit.pound: // Pound ->
        switch (dst) {
          case WeightUnit.kg:
            return new Weight.kg(value * pound_kg);
          case WeightUnit.g:
            return new Weight.g(value * pound_kg * kg_g);
          case WeightUnit.oz:
            return new Weight.oz(value * pound_oz);
          case WeightUnit.pound:
            return this;
        }
        break;
      case WeightUnit.oz: // oz ->
        switch (dst) {
          case WeightUnit.kg:
            return new Weight.kg(value / pound_oz * pound_kg);
          case WeightUnit.g:
            return new Weight.g(value * oz_g);
          case WeightUnit.oz:
            return this;
          case WeightUnit.pound:
            return new Weight.pound(value / pound_oz);
        }
        break;
    }
  }
}

abstract class Length extends ValueUnit<Length, LengthUnit> implements JsonSupport {
  factory Length.fromJsonString(String text) => new _LengthImpl(new Map.from(JSON.decode(text)));
  factory Length.fromMap(Map data) => new _LengthImpl(data);

  factory Length.of(LengthUnit unit, double value) {
    return new Length.fromMap({"unit": {'S': nameOfEnum(unit)}, "value": {'N': value}});
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
        _unit = new CachedProp<LengthUnit>(
            data, 'unit', (map) => enumByName(LengthUnit.values, map['S']), (v) => {'S': nameOfEnum(v)});

  Map get asMap => _data;

  double get value => double.parse(_data['value']);
  set value(double v) => _data['value'] = v.toString();

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
