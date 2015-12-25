library triton_note.service.reports;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/photo.dart';
import 'package:triton_note/service/aws/cognito.dart';
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
    return new Report.fromData(map[DynamoDB.CONTENT], map['REPORT_ID'],
        new DateTime.fromMillisecondsSinceEpoch(map['DATE_AT'], isUtc: true).toLocal());
  }, (Report obj) {
    return {DynamoDB.CONTENT: obj.toMap(), 'REPORT_ID': obj.id, 'DATE_AT': obj.dateAt};
  });

  static final PagingList<Report> paging = new PagingList(new _PagerReports());
  static List<Report> get _cachedList => paging.list;

  static List<Report> _addToCache(Report adding) => _cachedList
    ..add(adding)
    ..sort((a, b) => b.dateAt.compareTo(a.dateAt));

  static Future<Null> _loadFishes(Report report) async {
    final list = await TABLE_CATCH.query(
        "COGNITO_ID-REPORT_ID-index", {DynamoDB.COGNITO_ID: await cognitoId, TABLE_REPORT.ID_COLUMN: report.id});
    report.fishes
      ..clear()
      ..addAll(list);
  }

  static Future<Report> get(String id) async {
    final found = _cachedList.firstWhere((r) => r.id == id, orElse: () => null);
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
    _cachedList.removeWhere((r) => r.id == id);
    await TABLE_REPORT.delete(id);
  }

  static Future<Null> update(Report newReport) async {
    final oldReport = await get(newReport.id);
    assert(oldReport != null);

    _logger.finest("Update report:\n old=${oldReport}\n new=${newReport}");

    newReport.fishes.forEach((fish) => fish.reportId = newReport.id);

    List<Fishes> distinct(List<Fishes> src, List<Fishes> dst) => src.where((a) => dst.every((b) => b.id != a.id));

    // No old, On new
    Future adding() => Future.wait(distinct(newReport.fishes, oldReport.fishes).map(TABLE_CATCH.put));

    // On old, No new
    Future deleting() => Future.wait(distinct(oldReport.fishes, newReport.fishes).map((o) => TABLE_CATCH.delete(o.id)));

    // On old, On new
    Future marging() => Future.wait(newReport.fishes.where((newFish) {
          final oldFish = oldReport.fishes.firstWhere((oldFish) => oldFish.id == newFish.id, orElse: () => null);
          return oldFish != null && oldFish.isNeedUpdate(newFish);
        }).map(TABLE_CATCH.update));

    Future updating() async {
      if (oldReport.isNeedUpdate(newReport)) TABLE_REPORT.update(newReport);
    }

    Future replaceCache() async {
      _cachedList.removeWhere((x) => x.id == newReport.id);
      _addToCache(newReport.clone());
    }

    await Future.wait([adding(), marging(), deleting(), updating(), replaceCache()]);
    _logger.finest("Count of cached list: ${_cachedList.length}");
  }

  static Future<Null> add(Report reportSrc) async {
    final report = reportSrc.clone();
    _logger.finest("Adding report: ${report}");

    await Future.wait([
      TABLE_REPORT.put(report),
      Future.wait(report.fishes.map((fish) => TABLE_CATCH.put(fish..reportId = report.id)))
    ]);
    await _addToCache(report);

    _logger.finest(() => "Added report: ${report}");
  }
}

class _PagerReports implements Pager<Report> {
  static const changedEx = "CognitoId Changed";

  Pager<Report> _db;
  Completer<Null> _ready;

  _PagerReports() {
    _refreshDb();

    CognitoIdentity.addChaningHook(_refreshDb);
  }

  toString() => "PagerReports(ready=${_ready?.isCompleted ?? false})";

  _refreshDb([String oldId, String newId]) async {
    if (_ready != null && !_ready.isCompleted) _ready.completeError(changedEx);
    _ready = new Completer();
    _db = null;
    Reports.paging.reset();

    if (oldId != null && newId != null) await Photo.moveCognitoId(oldId, newId);
    cognitoId.then((currentId) {
      assert(currentId == newId || newId == null);

      _logger.info(() => "Refresh pager: cognito id is changed to ${currentId}");
      _db = Reports.TABLE_REPORT.queryPager("COGNITO_ID-DATE_AT-index", DynamoDB.COGNITO_ID, currentId, false);

      _ready.complete();
    });
  }

  bool get hasMore => _db?.hasMore ?? true;

  void reset() => _db?.reset();

  Future<List<Report>> more(int pageSize) async {
    try {
      await _ready.future;
      final cached = Reports._cachedList;
      final list = (await _db.more(pageSize)).where((r) => cached.every((c) => c.id != r.id));
      await Future.wait(list.map(Reports._loadFishes));
      _logger.finer(() => "Loaded reports: ${list}");
      return list;
    } catch (ex) {
      if (ex != changedEx) throw ex;
      return [];
    }
  }
}
