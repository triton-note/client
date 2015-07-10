library triton_note.service.reports;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/service/server.dart';

final _logger = new Logger('Reports');

class Reports {
  static const pageSize = 30;

  static List<Report> _allList;
  static Future<List<Report>> get allList async => (_allList != null) ? (_allList) : refresh();

  static bool _hasMore = true;
  static bool get hasMore => _hasMore;

  static Future<List<Report>> refresh() async {
    _allList = await Server.load(pageSize);
    if (_allList.length < pageSize) _hasMore = false;
    return _allList;
  }
  static Future<List<Report>> more() async {
    if (_allList == null) return refresh();
    else if (_hasMore) {
      final list = await Server.load(pageSize, _allList.last);
      _allList.addAll(list);
      if (list.length < pageSize) _hasMore = false;
    }
    return _allList;
  }

  static Future<Report> get(String id) => Server.read(id);
  static Future<Null> remove(String id) => Server.remove(id);

  /**
   * Expected to be called by UploadSession.submit
   */
  static Future<Null> add(Report report) async {
    (await allList)
      ..add(report)
      ..sort((a, b) => b.dateAt.compareTo(a.dateAt));
  }
}
