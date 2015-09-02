library triton_note.service.reports;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/service/aws/dynamodb.dart';
import 'package:triton_note/util/pager.dart';

final _logger = new Logger('Reports');

class Reports {
  static const DATE_AT = "DATE_AT";

  static final DynamoDB_Table<Fishes> TABLE_CATCH = new DynamoDB_Table("CATCH", "CATCH_ID", (Map map) {
    return new Fishes.fromData(map[DynamoDB.CONTENT], map['CATCH_ID'], map['REPORT_ID']);
  }, (Fishes obj) {
    return {DynamoDB.CONTENT: obj.toMap(), 'REPORT_ID': obj.reportId};
  });

  static final DynamoDB_Table<Report> TABLE_REPORT = new DynamoDB_Table("REPORT", "REPORT_ID", (Map map) {
    return new Report.fromData(
        map[DynamoDB.CONTENT], map['REPORT_ID'], new DateTime.fromMillisecondsSinceEpoch(map['DATE_AT'], isUtc: true));
  }, (Report obj) {
    return {DynamoDB.CONTENT: obj.toMap(), 'REPORT_ID': obj.id, 'DATE_AT': obj.dateAt.toUtc().millisecondsSinceEpoch};
  });

  static Future<PagingList<Report>> paging =
      DynamoDB.cognitoId.then((cognitoId) => new PagingList(new _PagerReports(cognitoId)));
  static Future<List<Report>> get _cachedList async => (await paging).list;

  static Future<Report> _fromCache(String id) async =>
      (await _cachedList).isEmpty ? null : (await _cachedList).firstWhere((r) => r.id == id, orElse: () => null);

  static Future<List<Report>> _addToCache(Report adding) async => (await _cachedList)
    ..add(adding)
    ..sort((a, b) => b.dateAt.compareTo(a.dateAt));

  static Future<Null> _loadFishes(Report report) async {
    final list = await TABLE_CATCH.query("COGNITO_ID-REPORT_ID-index", {
      DynamoDB.COGNITO_ID: await DynamoDB.cognitoId,
      TABLE_REPORT.ID_COLUMN: report.id
    });
    report.fishes
      ..clear()
      ..addAll(list);
  }

  static Future<Report> get(String id) async {
    final found = await _fromCache(id);
    if (found != null) {
      return found.clone();
    } else {
      final report = await TABLE_REPORT.get(id);
      await _loadFishes(report);
      _addToCache(report);
      return report.clone();
    }
  }

  static Future<Null> remove(String id) async {
    _logger.fine("Removing report.id: ${id}");
    (await _cachedList).removeWhere((r) => r.id == id);
    await TABLE_REPORT.delete(id);
  }

  static Future<Null> update(Report newReport) async {
    final oldReport = await _fromCache(newReport.id);
    assert(oldReport != null);

    _logger.finest("Update report:\n old=${oldReport}\n new=${newReport}");

    newReport.fishes.forEach((fish) => fish.reportId = newReport.id);

    // No old, On new
    final adding = Future.wait(newReport.fishes.where((fish) => fish.id == null).map(TABLE_CATCH.put));

    // On old, No new
    final deleting =
        Future.wait(oldReport.fishes
            .map((o) => o.id)
            .where((oldId) => newReport.fishes.every((fish) => fish.id != oldId))
            .map(TABLE_CATCH.delete));

    // On old, On new
    final marging = Future.wait(newReport.fishes.where((newFish) {
      final oldFish = oldReport.fishes.firstWhere((oldFish) => oldFish.id == newFish.id, orElse: () => null);
      return oldFish != null && oldFish.isNeedUpdate(newFish);
    }).map(TABLE_CATCH.update));

    oldReport.fishes
      ..clear()
      ..addAll(newReport.fishes.map((f) => f.clone()).toList());

    final updating = oldReport.isNeedUpdate(newReport)
        ? TABLE_REPORT.update(newReport).then((_) {
      oldReport.update(newReport);
    })
        : new Future.value(null);

    await Future.wait([adding, marging, deleting, updating]);
  }

  static Future<Null> add(Report reportSrc) async {
    final report = reportSrc.clone();

    _logger.finest("Adding report: ${report}");
    await TABLE_REPORT.put(report);
    _logger.finest(() => "Added report: ${report}");

    await Future.wait(report.fishes.map((fish) => TABLE_CATCH.put(fish..reportId = report.id)));

    _addToCache(report);
  }
}

class _PagerReports implements Pager<Report> {
  final String cognitoId;
  final Pager<Report> _db;

  _PagerReports(String id)
      : this.cognitoId = id,
        _db = Reports.TABLE_REPORT.queryPager("COGNITO_ID-DATE_AT-index", DynamoDB.COGNITO_ID, id, false);

  bool get hasMore => _db.hasMore;

  void reset() => _db.reset();

  Future<List<Report>> more(int pageSize) async {
    final list = await _db.more(pageSize);
    await Future.wait(list.map(Reports._loadFishes));
    _logger.finer(() => "Loaded reports: ${list}");
    return list;
  }
}
