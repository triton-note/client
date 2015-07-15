library tiroton_note.formatter.temperature;

import 'package:angular/angular.dart';

import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/preferences.dart';
import 'package:triton_note/util/enums.dart';

@Formatter(name: 'temperatureFilter')
class TemperatureFormatter {
  static Measures _measures;

  TemperatureFormatter() {
    if (_measures == null) UserPreferences.measures.then((v) => _measures = v);
  }

  String call(Temperature src, [int digits = 0]) {
    if (_measures == null) return null;

    final dst = src.convertTo(_measures.temperature);
    return "${round(dst.value, digits)} °${nameOfEnum(dst.unit)[0]}";
  }
}
