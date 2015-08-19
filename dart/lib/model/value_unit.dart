library triton_note.model.value_unit;

import 'dart:math';

import 'package:logging/logging.dart';

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

  U get _standardUnit;
  A asStandard() => convertTo(_standardUnit);

  @override
  bool operator ==(o) => o is A && o.value == value && o.unit == unit;

  @override
  String toString() => "${value}(${nameOfEnum(unit)})";
}

abstract class Temperature extends ValueUnit<Temperature, TemperatureUnit> {
  static const TemperatureUnit STANDARD_UNIT = TemperatureUnit.Cels;

  static double convertToStandard(TemperatureUnit unit, num value) =>
      (unit == null || value == null) ? null : new Temperature.of(unit, value).convertTo(STANDARD_UNIT).value;

  final _standardUnit = STANDARD_UNIT;

  Temperature();

  factory Temperature.of(TemperatureUnit unit, num value) => new _TemperatureImpl(value.toDouble(), unit);
  factory Temperature.standard(num value) => new Temperature.of(STANDARD_UNIT, value);

  factory Temperature.Cels(num value) => new Temperature.of(TemperatureUnit.Cels, value);
  factory Temperature.Fahr(num value) => new Temperature.of(TemperatureUnit.Fahr, value);
}
enum TemperatureUnit { Cels, Fahr }

class _TemperatureImpl extends Temperature {
  double value;
  final TemperatureUnit unit;

  _TemperatureImpl(this.value, this.unit);

  Temperature convertTo(TemperatureUnit dst) {
    _logger.finest("Converting ${this} to '${dst}'");
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

abstract class Weight extends ValueUnit<Weight, WeightUnit> {
  static const WeightUnit STANDARD_UNIT = WeightUnit.g;

  static double convertToStandard(WeightUnit unit, num value) =>
      (unit == null || value == null) ? null : new Weight.of(unit, value).convertTo(STANDARD_UNIT).value;

  final _standardUnit = STANDARD_UNIT;

  Weight();

  factory Weight.of(WeightUnit unit, num value) => new _WeightImpl(value.toDouble(), unit);
  factory Weight.standard(num value) => new Weight.of(STANDARD_UNIT, value);

  factory Weight.kg(num value) => new Weight.of(WeightUnit.kg, value);
  factory Weight.pound(num value) => new Weight.of(WeightUnit.pound, value);
  factory Weight.g(num value) => new Weight.of(WeightUnit.g, value);
  factory Weight.oz(num value) => new Weight.of(WeightUnit.oz, value);
}
enum WeightUnit { kg, g, pound, oz }

class _WeightImpl extends Weight {
  static const kg_g = 1000;
  static const pound_oz = 16;
  static const oz_g = 28.349523125;
  static const pound_kg = 0.45359237;

  double value;
  final WeightUnit unit;

  _WeightImpl(this.value, this.unit);

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

abstract class Length extends ValueUnit<Length, LengthUnit> {
  static const LengthUnit STANDARD_UNIT = LengthUnit.cm;

  static double convertToStandard(LengthUnit unit, num value) =>
      (unit == null || value == null) ? null : new Length.of(unit, value).convertTo(STANDARD_UNIT).value;

  final _standardUnit = STANDARD_UNIT;

  Length();

  factory Length.of(LengthUnit unit, num value) => new _LengthImpl(value.toDouble(), unit);
  factory Length.standard(num value) => new Length.of(STANDARD_UNIT, value);

  factory Length.cm(num value) => new Length.of(LengthUnit.cm, value);
  factory Length.inch(num value) => new Length.of(LengthUnit.inch, value);
}

enum LengthUnit { cm, inch }

class _LengthImpl extends Length {
  static const inchToCm = 2.54;

  double value;
  final LengthUnit unit;

  _LengthImpl(this.value, this.unit);

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
