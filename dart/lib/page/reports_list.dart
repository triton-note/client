library triton_note.page.reports_list;

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/service/reports.dart';
import 'package:triton_note/util/main_frame.dart';
import 'package:triton_note/util/pager.dart';

final _logger = new Logger('ReportsListPage');

@Component(
    selector: 'reports-list',
    templateUrl: 'packages/triton_note/page/reports_list.html',
    cssUrl: 'packages/triton_note/page/reports_list.css',
    useShadowDom: true)
class ReportsListPage extends MainFrame {
  PagingList<Report> reports;

  ReportsListPage(Router router) : super(router) {
    Reports.paging.then((list) {
      reports = list;
    });
  }

  goReport(String id) => rippling(() {
    router.go('report-detail', {'reportId': id});
  });

  addReport() {
    router.go('add', {});
  }
}
