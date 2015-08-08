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

  static PagingDB _pager;

  static Report _fromCache(String id) =>
      _cachedList == null ? null : _cachedList.firstWhere((r) => r.id == id, orElse: () => null);

  static List<Report> _addToCache(Report adding) => (_cachedList == null) ? null : _cachedList
    ..add(adding)
    ..sort((a, b) => b.dateAt.compareTo(a.dateAt));

  static Future<Null> _loadCatches(Report report) async {
    report.fishes = await DynamoDB.TABLE_CATCH.query("COGNITO_ID-REPORT_ID-index", {
      DynamoDB.COGNITO_ID: await DynamoDB.cognitoId,
      DynamoDB.TABLE_REPORT.ID_COLUMN: report.id
    });
  }

  static Future<List<Report>> refresh() async {
    if (_pager == null) {
      _pager = DynamoDB.TABLE_REPORT.createPager(
          "COGNITO_ID-DATE_AT-index", DynamoDB.COGNITO_ID, await DynamoDB.cognitoId, false);
    } else {
      _pager.reset();
    }
    _cachedList = [];
    return _more();
  }
  static Future<List<Report>> more() async {
    if (_cachedList == null) return refresh();
    return _more();
  }
  static Future<List<Report>> _more() async {
    final list = await _pager.more(pageSize);
    await Future.wait(list.map(_loadCatches));
    _logger.finer(() => "Loaded reports: ${list}");

    _cachedList.addAll(list);
    return _cachedList;
  }

  static Future<Report> get(String id) async {
    final found = _fromCache(id);
    if (found != null) {
      return found.clone();
    } else {
      final report = await DynamoDB.TABLE_REPORT.get(id);
      await _loadCatches(report);
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

    _logger.finest("Update report: old=${oldReport} new=${newReport}");
    if (oldReport.asMap == newReport.asMap) return;

    final oldFishes = oldReport.fishes;
    final newFishes = newReport.fishes;
    final oldFishesIDs = oldFishes.map((o) => o.id).toSet();
    final newFishesIDs = newFishes.map((o) => o.id).toSet();

    newFishes.forEach((fish) => fish.reportId = newReport.id);

    final adding = Future.wait(newFishes.where((fish) => fish.id == null).map(DynamoDB.TABLE_CATCH.put));
    final notFounds = oldFishesIDs.difference(newFishesIDs);
    final deleting = Future.wait(notFounds.map(DynamoDB.TABLE_CATCH.delete));
    final marging =
        Future
            .wait(
                newFishes
                    .where((newFish) => oldFishesIDs.contains(newFish.id) &&
                        oldFishes.firstWhere((oldFish) => oldFish.id == newFish.id).asMap != newFish.asMap)
                    .map(DynamoDB.TABLE_CATCH.update));

    final updating =
        (oldReport.asMap == newReport.asMap) ? new Future.value(null) : DynamoDB.TABLE_REPORT.update(newReport);

    await Future.wait([adding, marging, deleting, updating]);
    oldReport.copyFrom(newReport);
  }

  static Future<Null> add(Report reportSrc) async {
    final report = reportSrc.clone();

    _logger.finest("Adding report: ${report}");
    await DynamoDB.TABLE_REPORT.put(report);
    _logger.finest(() => "Added report: ${report}");

    await Future.wait(report.fishes.map((fish) => DynamoDB.TABLE_CATCH.put(fish..reportId = report.id)));

    _addToCache(report);
  }
}
