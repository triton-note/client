library triton_note.page.reports_list;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/service/reports.dart';
import 'package:triton_note/util/cordova.dart';
import 'package:triton_note/util/main_frame.dart';
import 'package:triton_note/util/pager.dart';

final _logger = new Logger('ReportsListPage');

@Component(
    selector: 'reports-list',
    templateUrl: 'packages/triton_note/page/reports_list.html',
    cssUrl: 'packages/triton_note/page/reports_list.css',
    useShadowDom: true)
class ReportsListPage extends MainFrame {
  final pageSize = 20;

  PagingList<Report> reports;

  ReportsListPage(Router router) : super(router);

  bool get noReports => reports != null && reports.list.isEmpty && !reports.hasMore;

  void onShadowRoot(ShadowRoot sr) {
    super.onShadowRoot(sr);

    Reports.paging.then((paging) async {
      hideSplashScreen();

      await paging.more(pageSize);
      reports = paging;
    });
  }

  goReport(String id) => rippling(() {
        router.go('report-detail', {'reportId': id});
      });

  addReport() {
    router.go('add', {});
  }
}
