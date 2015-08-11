library triton_note.service.catches;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/service/aws/dynamodb.dart';
import 'package:triton_note/service/googlemaps_browser.dart';
import 'package:triton_note/service/reports.dart';

final _logger = new Logger('Catches');

class Catches {
  static Future<List<Catches>> inArea(LatLngBounds bounds, [bool includeOthers = false]) async {
    final exp = ["#C.#L.#G.#LAT BETWEEN :LATD AND :LATU", "#C.#L.#G.#LNG BETWEEN :LNGD AND :LNGU"];
    final names = {"#C": "CONTENT", "#L": "location", "#G": "geoinfo", "#LAT": "latitude", "#LNG": "longitude"};
    final values = {
      ":LATU": bounds.northEast.latitude,
      ":LATD": bounds.southWest.latitude,
      ":LNGU": bounds.northEast.longitude,
      ":LNGD": bounds.southWest.longitude
    };
    if (!includeOthers) {
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
