library triton_note.page.experiment;

import 'dart:convert';
import 'dart:html';
import 'dart:js';

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

  fbLogin() async {
    try {
      final result = await FBConnect.login();
      window.alert("login: ${result}");
    } catch (ex) {
      window.alert("login: Error: ${ex}");
    }
  }

  fbLogout() async {
    try {
      final result = await FBConnect.logout();
      window.alert("logout: ${result}");
    } catch (ex) {
      window.alert("logout: Error: ${ex}");
    }
  }

  fbName() async {
    try {
      final result = await FBConnect.getName();
      window.alert("getName: ${result}");
    } catch (ex) {
      window.alert("getName: Error: ${ex}");
    }
  }

  fbGain() async {
    try {
      final result = await FBConnect.grantPublish();
      window.alert("grantPublish: ${result}");
    } catch (ex) {
      window.alert("grantPublish: Error: ${ex}");
    }
  }

  fbSettings() async {
    try {
      final result = await FBSettings.load();
      window.alert("getAppId: ${result.appId}");
    } catch (ex) {
      window.alert("getAppId: Error: ${ex}");
    }
  }

  crash() {
    FabricCrashlytics.crash('Crash by user');
  }
}
