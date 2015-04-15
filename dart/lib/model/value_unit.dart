library value_unit;

import 'package:triton_note/util/enums.dart';
import 'package:triton_note/util/json_support.dart';

abstract class Temperature implements JsonSupport {
  double value;
  final TemperatureUnit unit;

  factory Temperature.fromJsonString(String text) => new _TemperatureImpl(JSON.decode(text));
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

  Temperature convertTo(TemperatureUnit dst);
}
enum TemperatureUnit { Cels, Fahr }

class _TemperatureImpl implements Temperature {
  Map _data;
  _TemperatureImpl(this._data);
  Map toMap() => new Map.from(_data);

  double get value => _data['value'];
  set value(double v) => _data['value'] = v;

  TemperatureUnit get unit => (_data['unit'] == null) ? null : enumByName(TemperatureUnit.values, _data['unit']);
  set unit(TemperatureUnit v) => _data['unit'] = nameOfEnum(v);

  Temperature convertTo(TemperatureUnit dst) {
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

abstract class Weight implements JsonSupport {
  double value;
  final WeightUnit unit;

  factory Weight.fromJsonString(String text) => new _WeightImpl(JSON.decode(text));
  factory Weight.fromMap(Map data) => new _WeightImpl(data);

  factory Weight.of(WeightUnit unit, double value) {
    return new Weight.fromMap({"unit": nameOfEnum(unit), "value": value});
  }
  factory Weight.kg(double value) {
    return new Weight.of(WeightUnit.kg, value);
  }
  factory Weight.pond(double value) {
    return new Weight.of(WeightUnit.pond, value);
  }

  Weight convertTo(WeightUnit dst);
}
enum WeightUnit { kg, pond }

class _WeightImpl implements Weight {
  static const pondToKg = 0.4536;

  Map _data;
  _WeightImpl(this._data);
  Map toMap() => new Map.from(_data);

  double get value => _data['value'];
  set value(double v) => _data['value'] = v;

  WeightUnit get unit => (_data['unit'] == null) ? null : enumByName(WeightUnit.values, _data['unit']);
  set unit(WeightUnit v) => _data['unit'] = nameOfEnum(v);

  Weight convertTo(WeightUnit dst) {
    if (this.unit == dst) return this;
    else {
      switch (dst) {
        case WeightUnit.kg:
          return new Weight.kg(value * pondToKg);
        case WeightUnit.pond:
          return new Weight.pond(value / pondToKg);
      }
    }
  }
}

abstract class Length implements JsonSupport {
  double value;
  final LengthUnit unit;

  factory Length.fromJsonString(String text) => new _LengthImpl(JSON.decode(text));
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

  Length convertTo(LengthUnit dst);
}

enum LengthUnit { cm, inch }

class _LengthImpl implements Length {
  static const inchToCm = 2.54;

  Map _data;
  _LengthImpl(this._data);
  Map toMap() => new Map.from(_data);

  double get value => _data['value'];
  set value(double v) => _data['value'] = v;

  LengthUnit get unit => (_data['unit'] == null) ? null : enumByName(LengthUnit.values, _data['unit']);
  set unit(LengthUnit v) => _data['unit'] = nameOfEnum(v);

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
