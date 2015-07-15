library triton_note.util.main_frame;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';

final _logger = new Logger('MainFrame');

Future alfterRippling(Proc()) {
  return new Future.delayed(new Duration(milliseconds: 250), Proc);
}

class MainFrame extends ShadowRootAware {
  final Router router;
  ShadowRoot _root;
  ShadowRoot get root => _root;
  get drawerPanel => root.querySelector('core-drawer-panel#mainFrame');

  MainFrame(this.router);

  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
  }

  rippling(proc()) => alfterRippling(proc);

  void toggleMenu() {
    drawerPanel.togglePanel();
  }

  void back() {
    rippling(window.history.back);
  }

  void _goByMenu(String routeId) => rippling(() {
    _logger.info("Going to ${routeId}");
    router.go(routeId, {});
    toggleMenu();
  });
  void goReportsList() => _goByMenu('reports-list');
  void goPreferences() => _goByMenu('preferences');
  void goDistributions() => _goByMenu('distributions');
}
