library triton_note.service.infer_spotname;

import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/model/report.dart';
import 'package:triton_note/service/aws/dynamodb.dart';
import 'package:triton_note/service/reports.dart';

final Logger _logger = new Logger('Inference');

class Inference {
  static Future<List<Report>> around(GeoInfo here, [deltaLat = 0.008, deltaLng = 0.008]) async {
    _logger.fine(() => "Search reports around ${here}");

    final exmap = new ExpressionMap();
    final content = exmap.putName("CONTENT");
    final location = exmap.putName("location");
    final geoinfo = exmap.putName("geoinfo");
    final latitude = exmap.putName("latitude");
    final longitude = exmap.putName("longitude");

    cond(String key, double lower, double upper) {
      final name = "${content}.${location}.${geoinfo}.${key}";
      final kLower = exmap.putValue(lower);
      final kUpper = exmap.putValue(upper);

      if (lower < upper) {
        return "${name} BETWEEN ${kLower} AND ${kUpper}";
      } else {
        return "(${name} >= ${kLower} OR ${name} <= ${kUpper})";
      }
    }
    final north = min(here.latitude + deltaLat, 90);
    final south = max(here.latitude - deltaLat, -90);
    final east = (here.longitude + deltaLng + 180) % 360 - 180;
    final west = (here.longitude - deltaLng + 180) % 360 - 180;

    final expression = [cond(latitude, south, north), cond(longitude, west, east)].join(" AND ");

    final reports = await Reports.TABLE_REPORT.scan(expression, exmap.names, exmap.values);
    _logger.finest(() => "Found around ${here}: ${reports.length} reports");
    return reports;
  }

  static Future<String> spotName(GeoInfo here) async {
    _logger.fine(() => "Inferring spotName: ${here}");

    final List<Location> locations = (await around(here)).map((r) => r.location).toList();
    locations.sort((a, b) {
      final v = here.distance(a.geoinfo) - here.distance(b.geoinfo);
      if (v == 0) return 0;
      else if (v < 0) return -1;
      else if (v > 0) return 1;
    });
    _logger.fine(() => "Sorted locations: ${locations}");

    return locations.isEmpty ? null : locations.first.name;
  }

  static Future<Tide> tideState(GeoInfo here, double degMoon) async {
    _logger.fine(() => "Inferring tideState: ${here}, ${degMoon}");

    final moonAngle = ((degMoon - here.longitude) + 180) % 180;
    _logger.fine("Moon Angle origin(${here}) -> moon(${degMoon}): ${moonAngle}");

    Tide byAngle(double angle) {
      if (angle < 30) return Tide.High;
      if (angle <= 90) return Tide.Flood;
      if (angle < 120) return Tide.Low;
      return Tide.Ebb;
    }
    final tideByAngle = byAngle(moonAngle);

    final reports = await around(here);

    return tideByAngle;
  }
}
