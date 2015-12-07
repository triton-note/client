library triton_note.page.experiment;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';

import 'package:triton_note/service/facebook.dart';
import 'package:triton_note/util/fabric.dart';
import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('ExperimentPage');

@Component(
    selector: 'experiment',
    templateUrl: 'packages/triton_note/page/experiment.html',
    cssUrl: 'packages/triton_note/page/experiment.css',
    useShadowDom: true)
class ExperimentPage extends MainFrame {
  ExperimentPage(Router router) : super(router) {}

  fbToken() async {
    try {
      final result = await FBConnect.getToken();
      window.alert("getToken: ${result}");
    } catch (ex) {
      window.alert("getToken: Error: ${ex}");
    }
  }

  crash() {
    FabricCrashlytics.crash('Crash by user');
  }
}
