library triton_note.service.preferences;

import 'package:logging/logging.dart';

import 'package:triton_note/model/value_unit.dart';

final _logger = new Logger('UserPreferences');

class UserPreferences {
  static LengthUnit get lengthUnit => LengthUnit.cm;
  static WeightUnit get weightUnit => WeightUnit.kg;
  static TemperatureUnit get temperatureUnit => TemperatureUnit.Cels;
}
