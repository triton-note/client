library triton_note.component.reports_list;

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/service/reports.dart';
import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('ReportsListComponent');

@Component(
    selector: 'reports-list', templateUrl: 'packages/triton_note/component/reports_list.html', useShadowDom: false)
class ReportsListComponent extends MainFrame {
  List<Report> reports;

  ReportsListComponent(Router router) : super(router) {
    Reports.allList.then((v) => reports = v);
  }

  refresh() {
    reports = null;
    Reports.refresh().then((list) {
      reports = list;
    });
  }

  goReport(String id) {
    router.go('report.detail', {'reportId': id});
  }

  addReport() {
    router.go('add', {});
  }
}
