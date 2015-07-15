library triton_note.service.preferences;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/server.dart';

final _logger = new Logger('UserPreferences');

class UserPreferences {
  static Measures _measures;
  static Future<Measures> get measures async =>
      (_measures != null) ? _measures : Server.loadMeasures().then((v) => _measures = v);

  static update(Measures v) => Server.updateMeasures(_measures = v);
}
