library triton_note.page.experiment;

import 'dart:convert';
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

  tryFB(String name, [List args = null]) => rippling(() {
        try {
          if (args == null) {
            args = [];
          }
          args.insert(0, (err, result) {
            _logger.info(() => 'Result of plugin.FBConnect.${name}: ${result}, error: ${err}');
            if (result != null) {
              result = JSON.decode(context['JSON'].callMethod('stringify', [result]));
            }
            window.alert("${name}\nResult: ${result}\n\nError: ${err}");
          });
          _logger.info(() => 'Calling plugin.FBConnect.${name}');
          context['plugin']['FBConnect'].callMethod(name, args);
        } catch (ex) {
          FabricCrashlytics.crash('${ex}');
        }
      });

  fbLogin() => tryFB('login');
  fbLogout() => tryFB('logout');
  fbName() => tryFB('getName');
  fbToken() => tryFB('getToken');
  fbGain() => tryFB('login', ['publish_actions']);
  fbMerge() => tryFB('login', ['publish_actions', 'public_profile']);

  crash() {
    FabricCrashlytics.crash('Crash by user');
  }
}
