library triton_note.service.catches;

import 'package:logging/logging.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/location.dart';

final _logger = new Logger('Catches');

class Catches {
  static List<Catches> around(GeoInfo pos, double r) {
    return [];
  }

  final String reportId; // if null, this catches is others.
  final GeoInfo pos;
  final Fishes fish;
  final DateTime dateAt;
  final Condition condition;

  Catches(this.reportId, this.pos, this.fish, this.dateAt, this.condition);
}
