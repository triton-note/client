library triton_note.service.infer_spotname;

import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/service/aws/dynamodb.dart';
import 'package:triton_note/service/reports.dart';

final Logger _logger = new Logger('InferSpotName');

class InferSpotName {
  static const deltaLat = 0.008;
  static const deltaLng = 0.008;

  static double distance(GeoInfo a, GeoInfo b) {
    final dLat = a.latitude - b.latitude;
    final dLng = a.longitude - b.longitude;
    return sqrt(pow(dLat, 2) + pow(dLng, 2));
  }

  static Future<List<Location>> around(GeoInfo here) async {
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
    return reports.map((r) => r.location).toList();
  }

  static Future<String> infer(GeoInfo here) async {
    final locations = await around(here);
    locations.sort((a, b) {
      final v = distance(a.geoinfo, here) - distance(b.geoinfo, here);
      if (v == 0) return 0;
      else if (v < 0) return -1;
      else if (v > 0) return 1;
    });

    return locations.isEmpty ? null : locations.first.name;
  }
}
