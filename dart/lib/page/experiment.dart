library triton_note.page.experiment;

import 'dart:html';
import 'dart:js';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';

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

  checkFacebook() => rippling(() {
        try {
          final fb = context['plugin']['FBConnect'];

          _logger.info(() => 'Calling plugin.FBConnect.getName');
          fb.callMethod('getName', [
            (err, result) {
              _logger.info(() => 'Result of plugin.FBConnect.getName: ${result}, error: ${err}');
              window.alert('Error: ${err}, Result: ${result}');
            }
          ]);

          _logger.info(() => 'Calling plugin.FBConnect.getStatus');
          fb.callMethod('getStatus', [
            (err, result) {
              _logger.info(() => 'Result of plugin.FBConnect.getStatus: ${result}, error: ${err}');
              window.alert('Error: ${err}, Result: ${result}');
            }
          ]);
        } catch (ex) {
          FabricCrashlytics.crash('${ex}');
        }
      });

  crash() {
    FabricCrashlytics.crash('Crash by user');
  }
}
