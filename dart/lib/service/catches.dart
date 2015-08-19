library triton_note.service.catches;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/service/aws/dynamodb.dart';
import 'package:triton_note/service/googlemaps_browser.dart';
import 'package:triton_note/service/reports.dart';
import 'package:triton_note/util/distributions_filters.dart';
import 'package:triton_note/util/enums.dart';

final _logger = new Logger('Catches');

class Catches {
  static Future<CatchesPager> inArea(LatLngBounds bounds, DistributionsFilter filter) async {
    final exp = new _Expression();
    final content = exp.putName("CONTENT");
    final location = exp.putName("location");
    final geoinfo = exp.putName("geoinfo");
    final latitude = exp.putName("latitude");
    final longitude = exp.putName("longitude");
    final vLatU = exp.putValue(bounds.northEast.latitude);
    final vLatD = exp.putValue(bounds.southWest.latitude);
    final vLngU = exp.putValue(bounds.northEast.longitude);
    final vLngD = exp.putValue(bounds.southWest.longitude);
    exp.addCond("${content}.${location}.${geoinfo}.${latitude} BETWEEN ${vLatD} AND ${vLatU}");
    exp.addCond("${content}.${location}.${geoinfo}.${longitude} BETWEEN ${vLngD} AND ${vLngU}");
    await exp.add(filter);

    return new CatchesPager(Reports.TABLE_REPORT.scanPager(exp.expression, exp.names, exp.values), filter);
  }

  final Fishes fish;
  final DateTime dateAt;
  final Location location;
  final Condition condition;

  Catches(this.fish, this.dateAt, this.location, this.condition);

  @override
  String toString() => "Catches(${dateAt}, ${location}, ${condition}, ${fish})";
}

class CatchesPager {
  static const int pageSize = 100;

  final PagingDB<Report> _pager;
  final DistributionsFilter filter;

  CatchesPager(this._pager, this.filter);

  bool get hasMore => _pager.hasMore;

  List<Fishes> _left = [];

  Future<List<Fishes>> more() async {
    Future<List<Fishes>> doMore() async {
      final reports = await _pager.more(pageSize);
      final list = await Future.wait(reports.map((report) async {
        await Reports.loadFishes(report);
        return report.fishes.where((fish) {
          if (filter.fish.isActiveName) {
            if (!fish.name.contains(filter.fish.name)) return false;
          }
          if (filter.fish.isActiveLength) {
            final value = fish.length.asStandard().value;
            if (filter.fish.isActiveLengthMin && value < filter.fish.lengthMin) return false;
            if (filter.fish.isActiveLengthMax && value > filter.fish.lengthMax) return false;
          }
          if (filter.fish.isActiveWeight) {
            final value = fish.weight.asStandard().value;
            if (filter.fish.isActiveWeightMin && value < filter.fish.weightMin) return false;
            if (filter.fish.isActiveWeightMax && value > filter.fish.weightMax) return false;
          }
          return true;
        }).map((fish) => new Catches(fish, report.dateAt, report.location, report.condition));
      }));
      return list.expand((a) => a).toList();
    }

    while (_left.length < pageSize && _pager.hasMore) {
      _left.addAll(await doMore());
    }
    final result = _left.take(pageSize);
    _left = _left.sublist(result.length);
    return result.toList();
  }
}

class _Expression {
  final List<String> conds = [];
  final Map<String, String> _names = {};
  final Map<dynamic, String> _values = {};

  String get expression => conds.join(" AND ");
  Map<String, String> get names => _reverse(_names);
  Map<String, dynamic> get values => _reverse(_values);
  Map _reverse(Map src) {
    final result = {};
    src.forEach((key, value) {
      result[value] = key;
    });
    return result;
  }

  String _put(Map<dynamic, String> map, String pre, value) {
    if (map.containsKey(value)) return map[value];
    return map[value] = "${pre}${map.length + 1}";
  }
  String putName(String name) => _put(names, "#N", name);
  String putValue(value) => _put(values, ":V", value);
  void addCond(String cond) => conds.add(cond);

  Future<Null> add(DistributionsFilter filter) async {
    if (!filter.isIncludeOthers) {
      addCond("${putName(DynamoDB.COGNITO_ID)} = ${putValue(await DynamoDB.cognitoId)}");
    }

    if (filter.cond.isActiveTemperature || filter.cond.isActiveWeather || filter.cond.isActiveTide) {
      final content = putName("CONTENT");
      final condition = putName("condition");

      if (filter.cond.isActiveTemperature) {
        final weather = putName("weather");
        final temp = putName("temperature");
        if (filter.cond.isActiveTemperatureMin) {
          addCond("${content}.${condition}.${weather}.${temp} >= ${putValue(filter.cond.temperatureMin)}");
        }
        if (filter.cond.isActiveTemperatureMax) {
          addCond("${content}.${condition}.${weather}.${temp} <= ${putValue(filter.cond.temperatureMax)}");
        }
      }
      if (filter.cond.isActiveWeather) {
        final weather = putName("weather");
        final nominal = putName("nominal");
        addCond("${content}.${condition}.${weather}.${nominal} = ${putValue(filter.cond.weatherNominal)}");
      }
      if (filter.cond.isActiveTide) {
        final tide = putName("tide");
        addCond("${content}.${condition}.${tide} = ${putValue(nameOfEnum(filter.cond.tide))}");
      }
    }

    if (filter.term.isActiveInterval) {
      final dateAt = putName("DATE_AT");
      addCond("${dateAt} >= ${putValue(filter.term.intervalFrom)}");
      addCond("${dateAt} <= ${putValue(filter.term.intervalTo)}");
    }
    if (filter.term.isActiveRecent) {
      final dateAt = putName("DATE_AT");
      final from =
          new DateTime.now().toUtc().millisecondsSinceEpoch - (filter.term.recentValue * filter.term.recentUnitValue);
      addCond("${dateAt} >= ${putValue(from)}");
    }
    if (filter.term.isActiveSeason) {
      final dateAt = putName("DATE_AT");

      List<String> terms = [];
      final thisYear = new DateTime.now().year;
      int pastYears = 10;
      while (pastYears > 0) {
        pastYears = pastYears - 1;
        final year = thisYear - pastYears;
        final overyear = (filter.term.seasonBegin < filter.term.seasonEnd) ? 0 : 1;

        final begin = new DateTime(year, filter.term.seasonBegin, 1).toUtc().millisecondsSinceEpoch;
        final end = new DateTime(year + overyear, filter.term.seasonEnd + 1, 1).toUtc().millisecondsSinceEpoch;
        terms.add("${dateAt} >= ${putValue(begin)} AND ${dateAt} <= ${putValue(end)}");
      }
      addCond("( ${terms.join(" OR ")} )");
    }
  }
}
