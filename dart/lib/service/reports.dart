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
    return new Report.fromData(
        map[DynamoDB.CONTENT], map['REPORT_ID'], new DateTime.fromMillisecondsSinceEpoch(map['DATE_AT'], isUtc: true));
  }, (Report obj) {
    return {DynamoDB.CONTENT: obj.toMap(), 'REPORT_ID': obj.id, 'DATE_AT': obj.dateAt.toUtc().millisecondsSinceEpoch};
  });

  static PagingList<Report> paging = new PagingList(new _PagerReports());
  static Future<List<Report>> get _cachedList async => (await paging).list;

  static Future<Report> _fromCache(String id) async =>
      (await _cachedList).firstWhere((r) => r.id == id, orElse: () => null);

  static Future<List<Report>> _addToCache(Report adding) async => (await _cachedList)
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

    List<Fishes> distinct(List<Fishes> src, List<Fishes> dst) => src.where((a) => dst.every((b) => b.id != a.id));

    // No old, On new
    final adding = Future.wait(distinct(newReport.fishes, oldReport.fishes).map(TABLE_CATCH.put));

    // On old, No new
    final deleting = Future.wait(distinct(oldReport.fishes, newReport.fishes).map((o) => TABLE_CATCH.delete(o.id)));

    // On old, On new
    final marging = Future.wait(newReport.fishes.where((newFish) {
      final oldFish = oldReport.fishes.firstWhere((oldFish) => oldFish.id == newFish.id, orElse: () => null);
      return oldFish != null && oldFish.isNeedUpdate(newFish);
    }).map(TABLE_CATCH.update));

    oldReport.fishes
      ..clear()
      ..addAll(newReport.fishes.map((f) => f.clone()));

    final updating = oldReport.isNeedUpdate(newReport)
        ? TABLE_REPORT.update(newReport).then((_) => oldReport.update(newReport))
        : new Future.value(null);

    await Future.wait([adding, marging, deleting, updating]);
    _logger.finest("Count of cached list: ${(await _cachedList).length}");
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
  Pager<Report> _db;
  Completer<Null> _ready = new Completer();

  _PagerReports() {
    cognitoId.then((id) => _refreshDb(null, id));
    CognitoIdentity.addChaningHook(() => new _CognitoIdHook(this));
  }

  Future<Null> _refreshDb(String previousId, String currentId) async {
    if (currentId != null) {
      _logger.info(() => "Refresh pager of reports: CognitoID is changed ${previousId} => ${currentId}");
      if (previousId != null) await Photo.moveCognitoId(previousId, currentId);
      _db = Reports.TABLE_REPORT.queryPager("COGNITO_ID-DATE_AT-index", DynamoDB.COGNITO_ID, currentId, false);
      if (!_ready.isCompleted) _ready.complete(_db);
    }
  }

  bool get hasMore => _db?.hasMore ?? true;

  void reset() => _db?.reset();

  Future<List<Report>> more(int pageSize) async {
    await _ready.future;
    final list = await _db.more(pageSize);
    await Future.wait(list.map(Reports._loadFishes));
    _logger.finer(() => "Loaded reports: ${list}");
    return list;
  }
}

class _CognitoIdHook implements ChangingHook {
  final _PagerReports pager;

  String oldId;

  _CognitoIdHook(this.pager);

  Future onStartChanging(String id) async {
    _logger.finest(() => "[_PagerReports] Starting changing cognito id: ${id}");
    oldId = id;
  }

  Future onFinishChanging(String newId) async {
    _logger.finest(() => "[_PagerReports] Finishing changing cognito id: ${newId}");
    if (newId != null && oldId != newId) {
      _logger.info(() => "Refresh pager of reports: CognitoID is changed ${oldId} => ${newId}");
      if (oldId != null) await Photo.moveCognitoId(oldId, newId);
      pager._db = Reports.TABLE_REPORT.queryPager("COGNITO_ID-DATE_AT-index", DynamoDB.COGNITO_ID, newId, false);
    }
  }

  Future onFailedChanging() async {}
}
