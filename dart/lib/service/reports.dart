library triton_note.service.reports;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/service/server.dart';

final _logger = new Logger('Reports');

class Reports {
  static const pageSize = 30;

  static List<Report> _cachedList;
  static Future<List<Report>> get allList async => (_cachedList != null) ? _cachedList : refresh();

  static bool _hasMore = true;
  static bool get hasMore => _hasMore;

  static Report _inCache(String id) => _cachedList.firstWhere((r) => r.id == id, orElse: () => null);

  static Future<List<Report>> refresh() async {
    _cachedList = await Server.load(pageSize);
    if (_cachedList.length < pageSize) _hasMore = false;
    return _cachedList;
  }
  static Future<List<Report>> more() async {
    if (_cachedList == null) return refresh();
    else if (_hasMore) {
      final list = await Server.load(pageSize, _cachedList.last);
      _cachedList.addAll(list);
      if (list.length < pageSize) _hasMore = false;
    }
    return _cachedList;
  }

  static Future<Report> get(String id) async {
    final found = _inCache(id);
    return found != null ? found : Server.read(id);
  }

  static Future<Null> remove(String id) {
    _logger.fine("Removing report.id: ${id}");
    _cachedList.removeWhere((r) => r.id == id);
    return Server.remove(id);
  }

  static Future<Null> update(Report report) async {
    final found = _inCache(report.id);
    if (found != null && found.asMap != report.asMap) {
      found.asMap
        ..clear()
        ..addAll(report.asMap);
      _logger.finest("Updated report: ${found}");
    }
    _logger.finest("Update report: ${report}");
    return Server.update(report);
  }

  /**
   * Expected to be called by UploadSession.submit
   */
  static Future<Null> add(Report report) async {
    _logger.finest("Adding report: ${report}");
    (await allList)
      ..add(report)
      ..sort((a, b) => b.dateAt.compareTo(a.dateAt));
  }
}
