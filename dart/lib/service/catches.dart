library triton_note.service.catches;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/service/aws/dynamodb.dart';
import 'package:triton_note/service/googlemaps_browser.dart';
import 'package:triton_note/service/reports.dart';
import 'package:triton_note/util/distributions_filters.dart';

final _logger = new Logger('Catches');

class Catches {
  static Future<List<Catches>> inArea(LatLngBounds bounds, DistributionsFilter filter) async {
    final exp = ["#C.#L.#G.#LAT BETWEEN :LATD AND :LATU", "#C.#L.#G.#LNG BETWEEN :LNGD AND :LNGU"];
    final names = {"#C": "CONTENT", "#L": "location", "#G": "geoinfo", "#LAT": "latitude", "#LNG": "longitude"};
    final values = {
      ":LATU": bounds.northEast.latitude,
      ":LATD": bounds.southWest.latitude,
      ":LNGU": bounds.northEast.longitude,
      ":LNGD": bounds.southWest.longitude
    };
    if (!filter.isIncludeOthers) {
      exp.add("#U = :U");
      names["#U"] = DynamoDB.COGNITO_ID;
      values[":U"] = await DynamoDB.cognitoId;
    }
    final reports = await DynamoDB.TABLE_REPORT.scan(exp.join(" AND "), names, values);
    final list = await Future.wait(reports.map((report) async {
      await Reports.loadFishes(report);
      return report.fishes.map((fish) => new Catches(fish, report.dateAt, report.location, report.condition));
    }));
    return list.expand((a) => a).toList();
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
