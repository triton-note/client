library reports_list_component;

import 'package:angular/angular.dart';
import 'package:triton_note/util/main_frame.dart';

@Component(
    selector: 'reports-list',
    templateUrl: 'packages/triton_note/component/reports_list.html')
class ReportsListComponent extends MainFrame {
  ReportsListComponent(Router router): super(router);
}
