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
  static Future<List<Report>> around(GeoInfo here, double deltaLat, double deltaLng) async {
    _logger.fine(() => "Search reports around ${here}: delta = latitude: ${deltaLat}, longitude: ${deltaLng}");

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
    reports.sort((a, b) {
      final v = here.distance(a.location.geoinfo) - here.distance(b.location.geoinfo);
      if (v == 0)
        return 0;
      else if (v < 0)
        return -1;
      else if (v > 0) return 1;
    });
    return reports;
  }

  static Future<String> spotName(GeoInfo here) async {
    _logger.fine(() => "Inferring spotName: ${here}");

    final reports = await around(here, 0.005, 0.005);

    return reports.isEmpty ? null : reports.first.location.name;
  }

  static const List<Tide> tides = const [Tide.High, Tide.Flood, Tide.Low, Tide.Ebb];
  static Future<Tide> tideState(GeoInfo here, double degMoon) async {
    _logger.fine(() => "Inferring tideState: ${here}, ${degMoon}");

    double outMargin(Tide tide, double degree) {
      final angle = (degree + 180) % 180;
      final range = 30;
      final index = tides.indexOf(tide);
      final min = index * 0;
      final max = min + range;
      if (angle < min) return angle - min;
      if (max <= angle) return max - angle - 1;
      return (angle - min - range / 2).abs();
    }
    Tide find(double offset) => tides.firstWhere((tide) => outMargin(tide, degMoon - here.longitude + offset) >= 0);

    Future<Tide> aggregate(double deltaLat, double deltaLng) async {
      final reports = await around(here, 0.35, 0.35);
      if (reports.isEmpty) return null;

      final Map<Tide, List<double>> groups = {};
      Tide.values.forEach((t) => groups[t] = []);
      reports.forEach((report) {
        final degree = report.condition.moon.earthLongitude - report.location.geoinfo.longitude;
        groups[report.condition.tide].add(degree);
      });

      double offset = 0.0;
      double diff = null;
      new List.generate(180, (i) => i).forEach((i) {
        final out = Tide.values.fold(0.0, (total, tide) {
          return total +
              groups[tide].fold(0.0, (v, degree) {
                return v + outMargin(tide, degree + i);
              });
        });
        if (diff == null || out < diff) {
          offset = i;
          diff = out;
        }
      });

      return find(offset);
    }
    Future<Tide> aggregation() async => await aggregate(0.35, 0.35) ?? await aggregate(90.0, 0.5);

    return await aggregation() ?? find(0.0);
  }
}
