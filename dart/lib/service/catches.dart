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
    final exp = new _Expression.report(filter);
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
    await exp.ready();

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

      final exp = new _Expression.catches(filter);
      final reportIdValue = exp.putValue(null);
      exp.addCond("${exp.putName(Reports.TABLE_REPORT.ID_COLUMN)} = ${reportIdValue}");
      await exp.ready();

      final expression = exp.expression;
      final names = exp.names;

      final list = await Future.wait(reports.map((report) async {
        final values = exp.values..[reportIdValue] = report.id;
        final fishList = await Reports.TABLE_CATCH.scan(expression, names, values);
        return fishList.map((fish) => new Catches(fish, report.dateAt, report.location, report.condition));
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

abstract class _Expression {
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

  final Completer _onReady = new Completer();
  Future<Null> ready() => _onReady.future;
  Future<Null> _doInit(DistributionsFilter filter);
  _init(DistributionsFilter filter) => _doInit(filter).then(_onReady.complete);

  _Expression();
  factory _Expression.report(DistributionsFilter filter) => new _ExpressionReport().._init(filter);
  factory _Expression.catches(DistributionsFilter filter) => new _ExpressionCatches().._init(filter);
}

class _ExpressionReport extends _Expression {
  Future<Null> _doInit(DistributionsFilter filter) async {
    if (!filter.isIncludeOthers) {
      addCond("${putName(DynamoDB.COGNITO_ID)} = ${putValue(await DynamoDB.cognitoId)}");
    }

    if (filter.cond.isActive_Any) {
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

    if (filter.term.isActive_Any) {
      final dateAt = putName("DATE_AT");

      if (filter.term.isActiveInterval) {
        addCond("${dateAt} >= ${putValue(filter.term.intervalFrom)}");
        addCond("${dateAt} <= ${putValue(filter.term.intervalTo)}");
      }
      if (filter.term.isActiveRecent) {
        final from =
            new DateTime.now().toUtc().millisecondsSinceEpoch - (filter.term.recentValue * filter.term.recentUnitValue);
        addCond("${dateAt} >= ${putValue(from)}");
      }
      if (filter.term.isActiveSeason) {
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
}

class _ExpressionCatches extends _Expression {
  Future<Null> _doInit(DistributionsFilter filter) async {
    if (filter.fish.isActive_Any) {
      final content = putName("CONTENT");
      if (filter.fish.isActiveName) {
        addCond("contains(${content}.${putName("name")}, ${putValue(filter.fish.name)})");
      }
      if (filter.fish.isActiveLength) {
        final length = putName("length");
        if (filter.fish.isActiveLengthMin) addCond("${content}.${length} >= ${putValue(filter.fish.lengthMin)}");
        if (filter.fish.isActiveLengthMax) addCond("${content}.${length} <= ${putValue(filter.fish.lengthMax)}");
      }
      if (filter.fish.isActiveWeight) {
        final weight = putName("weight");
        if (filter.fish.isActiveWeightMin) addCond("${content}.${weight} >= ${putValue(filter.fish.weightMin)}");
        if (filter.fish.isActiveWeightMax) addCond("${content}.${weight} <= ${putValue(filter.fish.weightMax)}");
      }
    }
  }
}
