library triton_note.component.report_detail;

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/service/reports.dart';
import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('ReportsDetailComponent');

@Component(selector: 'report-detail', templateUrl: 'packages/triton_note/component/report_detail.html')
class ReportsDetailComponent extends MainFrame {
  Report report;

  ReportsDetailComponent(Router router, RouteProvider routeProvider) : super(router) {
    final String reportId = routeProvider.parameters['reportId'];
    Reports.get(reportId).then((v) => report = v);
  }
}
