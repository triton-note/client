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

    return await Reports.TABLE_REPORT.scan(expression, exmap.names, exmap.values);
  }

  static Future<String> spotName(GeoInfo here) async {
    _logger.fine(() => "Inferring spotName: ${here}");

    final reports = await around(here, 0.005, 0.005);

    String name;
    double min;
    reports.forEach((report) {
      final v = here.distance(report.location.geoinfo);
      if (min == null || v < min) {
        min = v;
        name = report.location.name;
      }
    });
    _logger.fine(() => "Nearest spotName: ${name}, distance=${min}");
    return name;
  }

  static const List<Tide> tides = const [Tide.High, Tide.Flood, Tide.Low, Tide.Ebb];
  static Future<Tide> tideState(GeoInfo here, double degMoon) async {
    _logger.fine(() => "Inferring tideState: ${here}, ${degMoon}");

    range(Tide tide, double degree, proc(double angle, double min, double max)) {
      final width = 180.0;
      final step = width / tides.length;
      final min = tides.indexOf(tide) * step;
      return proc((degree + width) % width, min, min + step);
    }
    Tide find(double offset) {
      _logger.fine(() => "Getting tideState by offset: ${offset}");
      return tides.firstWhere((tide) => range(tide, degMoon - here.longitude + offset, (angle, min, max) {
            return min <= angle && angle < max;
          }));
    }

    Future<Tide> aggregate(double deltaLat, double deltaLng) async {
      final reports = await around(here, deltaLat, deltaLng);
      if (reports.isEmpty) return null;

      final Map<Tide, List<List<double>>> groups = {};
      Tide.values.forEach((t) => groups[t] = []);
      reports.forEach((report) {
        if (report.condition.moon.earthLongitude != null) {
          final weight = 1 / sqrt(report.location.geoinfo.distance(here) + 1);
          final degree = report.condition.moon.earthLongitude - report.location.geoinfo.longitude;
          _logger.finest(() =>
              "Tide state ${report.condition.tide}: location=${report.location.geoinfo} degree=${degree}, weight=${weight}");
          groups[report.condition.tide].add([weight, degree]);
        }
      });

      double offset;
      double diff;
      new List.generate(180, (i) => i).forEach((i) {
        final out = tides.fold(0.0, (pre, tide) {
          final degreeList = groups[tide];
          if (degreeList.isEmpty) return pre;

          final total = degreeList.fold(0.0, (pre, tuple) {
            final weight = tuple[0];
            final degree = tuple[1];
            return range(tide, degree + i, (angle, min, max) {
              final distance = (angle - (min + max) / 2).abs();
              return pre + distance * weight;
            });
          });
          return pre + total / degreeList.length;
        });

        if (diff == null || out < diff) {
          offset = i;
          diff = out;
        }
      });

      return find(offset);
    }
    Future<Tide> aggregation() async {
      try {
        final narrow = await aggregate(0.35, 0.35);
        return narrow != null ? narrow : await aggregate(90.0, 0.5);
      } catch (ex) {
        _logger.warning(() => "Failed to aggregate tideState: ${ex}");
        return null;
      }
    }

    final a = await aggregation();
    return a != null ? a : find(0.0);
  }
}
