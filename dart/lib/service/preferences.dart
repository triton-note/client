library triton_note.service.preferences;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/server.dart';

final _logger = new Logger('UserPreferences');

class UserPreferences {
  static Future<Measures> _measures;
  static Future<Measures> get measures {
    if (_measures == null) _measures = Server.loadMeasures();
    return _measures;
  }

  static update(Measures v) {
    _measures = new Future.value(v);
    Server.updateMeasures(v);
  }
}
