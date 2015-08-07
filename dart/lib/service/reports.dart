library triton_note.service.reports;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/service/aws/dynamodb.dart';

final _logger = new Logger('Reports');

class Reports {
  static const DATE_AT = "DATE_AT";
  static const pageSize = 30;

  static List<Report> _cachedList;
  static Future<List<Report>> get allList async => (_cachedList != null) ? _cachedList : refresh();

  static PagingDB pager;

  static Report _fromCache(String id) =>
      _cachedList == null ? null : _cachedList.firstWhere((r) => r.id == id, orElse: () => null);

  static List<Report> _addToCache(Report adding) => (_cachedList == null) ? null : _cachedList
    ..add(adding)
    ..sort((a, b) => b.dateAt.compareTo(a.dateAt));

  static Future<List<Report>> refresh() async {
    if (pager == null) {
      pager = DynamoDB.TABLE_REPORT.createPager(
          "COGNITO_ID-DATE_AT-index", DynamoDB.COGNITO_ID, await DynamoDB.cognitoId, false);
    } else {
      pager.reset();
    }
    _cachedList = await pager.more(pageSize);
    return _cachedList;
  }
  static Future<List<Report>> more() async {
    if (_cachedList == null) return refresh();
    _cachedList.addAll(await pager.more(pageSize));
    return _cachedList;
  }

  static Future<Report> get(String id) async {
    final found = _fromCache(id);
    if (found != null) {
      return new Report.fromMap(new Map.from(found.asMap));
    } else {
      final report = await DynamoDB.TABLE_REPORT.get(id);
      _addToCache(report);
      return report;
    }
  }

  static Future<Null> remove(String id) async {
    _logger.fine("Removing report.id: ${id}");
    _cachedList.removeWhere((r) => r.id == id);
    await DynamoDB.TABLE_REPORT.delete(id);
  }

  static Future<Null> update(Report newReport) async {
    final oldReport = _fromCache(newReport.id);
    assert(oldReport != null);

    if (oldReport.asMap == newReport.asMap) return;
    _logger.finest("Update report: old=${oldReport} new=${newReport}");

    final oldFishes = oldReport.fishes;
    final newFishes = newReport.fishes;

    final adding =
        Future.wait(newFishes.where((fish) => fish.id == null).map((fish) => DynamoDB.TABLE_CATCH.put(fish)));
    final notFounds = oldFishes.map((o) => o.id).toSet().difference(newFishes.map((o) => o.id).toSet());
    final deleting = Future.wait(notFounds.map(DynamoDB.TABLE_CATCH.delete));
    final marging =
        Future
            .wait(newFishes
                .where((newFish) => !notFounds.contains(newFish.id) &&
                    oldFishes.firstWhere((oldFish) => oldFish.id = newFish.id).asMap != newFish.asMap)
                .map((fish) {
      DynamoDB.TABLE_CATCH.update(fish);
    }));

    final updating =
        (oldReport.asMap == newReport.asMap) ? new Future.value(null) : DynamoDB.TABLE_REPORT.update(newReport);

    newFishes
      ..removeWhere((fish) => fish.id == null)
      ..addAll(await adding);
    await Future.wait([marging, deleting, updating]);
  }

  static Future<Null> add(Report report) async {
    _logger.finest("Adding report: ${report}");
    await DynamoDB.TABLE_REPORT.put(report);
    _logger.finest(() => "Added report: ${report}");

    await Future.wait(report.fishes.map((fish) => DynamoDB.TABLE_CATCH.put(fish..reportId = report.id)));

    _addToCache(report);
  }
}
