library triton_note.model.value_unit;

import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';

import 'package:triton_note/util/enums.dart';
import 'package:triton_note/util/getter_setter.dart';

final _logger = new Logger('ValueUnit');

String round(double v, int digits) {
  if (digits <= 0) return "${v.round()}";
  final d = pow(10, digits);
  return "${(v * d).round() / d}";
}

abstract class ValueUnit<A extends ValueUnit<A, U>, U> implements StreamedUpdate<A> {
  ValueUnit(this._value, this.unit);

  final StreamController<A> _updateStream = new StreamController.broadcast();
  Stream<A> get onUpdate => _updateStream.stream;

  double _value;
  double get value => _value;
  set value(double value) {
    _value = value;
    _logger.finest("Updated ${this} => ${value}");
    _updateStream.add(this);
  }

  final U unit;
  A convertTo(U dst);

  U get _standardUnit;
  A asStandard() => convertTo(_standardUnit);

  @override
  bool operator ==(o) => o is A && o.value == value && o.unit == unit;

  @override
  String toString() => "${value}(${nameOfEnum(unit)})";
}

enum TemperatureUnit { Cels, Fahr }

class Temperature extends ValueUnit<Temperature, TemperatureUnit> {
  static const TemperatureUnit STANDARD_UNIT = TemperatureUnit.Cels;

  static double convertToStandard(TemperatureUnit unit, num value) =>
      (unit == null || value == null) ? null : new Temperature.of(unit, value).convertTo(STANDARD_UNIT).value;

  final _standardUnit = STANDARD_UNIT;

  factory Temperature.of(TemperatureUnit unit, num value) => new Temperature(value.toDouble(), unit);
  factory Temperature.standard(num value) => new Temperature.of(STANDARD_UNIT, value);

  factory Temperature.Cels(num value) => new Temperature.of(TemperatureUnit.Cels, value);
  factory Temperature.Fahr(num value) => new Temperature.of(TemperatureUnit.Fahr, value);

  Temperature(double value, TemperatureUnit unit) : super(value, unit);

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

enum WeightUnit { kg, g, pound, oz }

class Weight extends ValueUnit<Weight, WeightUnit> {
  static const WeightUnit STANDARD_UNIT = WeightUnit.g;

  static double convertToStandard(WeightUnit unit, num value) =>
      (unit == null || value == null) ? null : new Weight.of(unit, value).convertTo(STANDARD_UNIT).value;

  final _standardUnit = STANDARD_UNIT;

  factory Weight.of(WeightUnit unit, num value) => new Weight(value.toDouble(), unit);
  factory Weight.standard(num value) => new Weight.of(STANDARD_UNIT, value);

  factory Weight.kg(num value) => new Weight.of(WeightUnit.kg, value);
  factory Weight.pound(num value) => new Weight.of(WeightUnit.pound, value);
  factory Weight.g(num value) => new Weight.of(WeightUnit.g, value);
  factory Weight.oz(num value) => new Weight.of(WeightUnit.oz, value);

  static const kg_g = 1000;
  static const pound_oz = 16;
  static const oz_g = 28.349523125;
  static const pound_kg = 0.45359237;

  Weight(double value, WeightUnit unit) : super(value, unit);

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

enum LengthUnit { cm, inch }

class Length extends ValueUnit<Length, LengthUnit> {
  static const LengthUnit STANDARD_UNIT = LengthUnit.cm;

  static double convertToStandard(LengthUnit unit, num value) =>
      (unit == null || value == null) ? null : new Length.of(unit, value).convertTo(STANDARD_UNIT).value;

  final _standardUnit = STANDARD_UNIT;

  factory Length.of(LengthUnit unit, num value) => new Length(value.toDouble(), unit);
  factory Length.standard(num value) => new Length.of(STANDARD_UNIT, value);

  factory Length.cm(num value) => new Length.of(LengthUnit.cm, value);
  factory Length.inch(num value) => new Length.of(LengthUnit.inch, value);

  static const inchToCm = 2.54;

  Length(double value, LengthUnit unit) : super(value, unit);

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
