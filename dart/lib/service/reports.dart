library triton_note.service.reports;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/service/aws/dynamodb.dart';

final _logger = new Logger('Reports');

class Reports {
  static const pageSize = 30;

  static Map _lastEvaluatedKey;
  static List<Report> _cachedList;
  static Future<List<Report>> get allList async => (_cachedList != null) ? _cachedList : refresh();

  static bool get hasMore => _lastEvaluatedKey == null || _lastEvaluatedKey.isNotEmpty;

  static Report _fromCache(String id) =>
      _cachedList == null ? null : _cachedList.firstWhere((r) => r.id == id, orElse: () => null);

  static List<Report> _addToCache(Report adding) => (_cachedList == null) ? null : _cachedList
    ..add(adding)
    ..sort((a, b) => b.dateAt.compareTo(a.dateAt));

  static Map _reducedMap(Report report) => new Map.from(report.asMap)..remove('fishes');

  static Future<List<Report>> _load() async {
    final params = {
      'Limit': pageSize,
      'ScanIndexForward': false,
      'KeyConditionExpression': "#N1 = :V1",
      'ExpressionAttributeNames': {'#N1': "CONGNITO_ID"},
      'ExpressionAttributeValues': {':V1': await DynamoDB.cognitoId}
    };
    if (_lastEvaluatedKey != null && _lastEvaluatedKey.isNotEmpty) {
      params['ExclusiveStartKey'] = _lastEvaluatedKey;
    }
    final result = await DynamoDB.TABLE_REPORT.invoke('query', params);
    if (result != null) {
      _lastEvaluatedKey = result['LastEvaluatedKey'];
      return result['Items'].map((m) => new Report.fromMap(m));
    } else {
      _lastEvaluatedKey = const {};
      return [];
    }
  }
  static Future<List<Report>> refresh() async {
    _cachedList = await _load();
    return _cachedList;
  }
  static Future<List<Report>> more() async {
    if (_cachedList == null) return refresh();
    if (hasMore) _cachedList.addAll(await _load());
    return _cachedList;
  }

  static Future<Report> get(String id) async {
    final found = _fromCache(id);
    if (found != null) {
      return new Report.fromMap(new Map.from(found.asMap));
    } else {
      final report = await DynamoDB.TABLE_REPORT.get(id).then((data) => new Report.fromMap(data));
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

    final adding = Future.wait(newFishes.where((fish) => fish.id == null).map((fish) {
      DynamoDB.TABLE_CATCH.put(fish.asMap, {'REPORT_ID': {'S': newReport.id}}).then((data) => new Fishes.fromMap(data));
    }));
    final notFounds = oldFishes.map((o) => o.id).toSet().difference(newFishes.map((o) => o.id).toSet());
    final deleting = Future.wait(notFounds.map(DynamoDB.TABLE_CATCH.delete));
    final marging =
        Future
            .wait(newFishes
                .where((newFish) => !notFounds.contains(newFish.id) &&
                    oldFishes.firstWhere((oldFish) => oldFish.id = newFish.id).asMap != newFish.asMap)
                .map((fish) {
      DynamoDB.TABLE_CATCH.update(fish.asMap);
    }));

    final oldMap = _reducedMap(oldReport);
    final newMap = _reducedMap(newReport);
    final updating = (oldMap == newMap)
        ? new Future.value(null)
        : DynamoDB.TABLE_REPORT.update(newMap, {'DATE_AT': {'N': newMap['dateAt']}});

    newFishes
      ..removeWhere((fish) => fish.id == null)
      ..addAll(await adding);
    await Future.wait([marging, deleting, updating]);
  }

  static Future<Null> add(Report report) async {
    _logger.finest("Adding report: ${report}");
    final content = _reducedMap(report);
    final newReport = await DynamoDB.TABLE_REPORT
        .put(content, {'DATE_AT': {'N': content['dateAt']}})
        .then((data) => new Report.fromMap(data));

    final flist = Future.wait(report.fishes.map((fish) {
      DynamoDB.TABLE_CATCH.put(fish.asMap, {'REPORT_ID': {'S': newReport.id}}).then((data) => new Fishes.fromMap(data));
    }));

    await flist.then((fishes) {
      newReport.fishes = fishes.toList();
      _addToCache(newReport);
    });
  }
}
