library main_frame;

import 'dart:html';

import 'package:angular/angular.dart';

class MainFrame implements ShadowRootAware {
  final Router router;
  var drawerPanel;
  
  MainFrame(this.router);
  
  @override
  onShadowRoot(ShadowRoot sr){
    drawerPanel = sr.getElementById('drawerPanel');
  }

  void toggleMenu() {
    drawerPanel.togglePanel();
  }

  void back() {
    window.history.back();
  }
  
  void goPreferences() {
    print("Going to preferences");
  }
}
