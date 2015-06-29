library triton_note.util.main_frame;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';

final _logger = new Logger('MainFrame');

class MainFrame {
  final Router router;
  get drawerPanel => document.getElementById('drawerPanel');

  MainFrame(this.router);

  Future rippling(Proc()) {
    return new Future.delayed(new Duration(milliseconds: 250), Proc);
  }

  void toggleMenu() {
    drawerPanel.togglePanel();
  }

  void back() {
    rippling(window.history.back);
  }

  void goPreferences() {
    _logger.info("Going to preferences");
  }
}
