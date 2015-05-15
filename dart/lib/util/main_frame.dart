library main_frame;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';

class MainFrame implements ShadowRootAware {
  final Router router;
  var drawerPanel;

  MainFrame(this.router);

  @override
  onShadowRoot(ShadowRoot sr) {
    drawerPanel = sr.getElementById('drawerPanel');
  }

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
    print("Going to preferences");
  }
}
