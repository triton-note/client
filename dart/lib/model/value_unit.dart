library value_unit;

class Temperature {
  double value;
  final TemperatureUnit unit;

  Temperature(this.value, this.unit);

  Temperature convertTo(TemperatureUnit dst) {
    if (this.unit == dst) return this;
    else {
      switch (dst) {
        case TemperatureUnit.Cels:
          return new Temperature((value - 32) * 5 / 9, dst);
        case TemperatureUnit.Fahr:
          return new Temperature(value * 9 / 5 + 32, dst);
      }
    }
  }
}

enum TemperatureUnit { Cels, Fahr }

class Weight {
  static const pondToKg = 0.4536;
  
  double value;
  final WeightUnit unit;

  Weight(this.value, this.unit);

  Weight convertTo(WeightUnit dst) {
    if (this.unit == dst) return this;
    else {
      switch (dst) {
        case WeightUnit.Kg:
          return new Weight(value * pondToKg, dst);
        case WeightUnit.Pond:
          return new Weight(value / pondToKg, dst);
      }
    }
  }
}

enum WeightUnit { Kg, Pond }

class Length {
  static const inchToCm = 2.54;
  
  double value;
  final LengthUnit unit;

  Length(this.value, this.unit);

  Length convertTo(LengthUnit dst) {
    if (this.unit == dst) return this;
    else {
      switch (dst) {
        case LengthUnit.Cm:
          return new Length(value * inchToCm, dst);
        case LengthUnit.Inch:
          return new Length(value / inchToCm, dst);
      }
    }
  }
}

enum LengthUnit { Cm, Inch }
