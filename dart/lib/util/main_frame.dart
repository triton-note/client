library triton_note.util.main_frame;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';

final _logger = new Logger('MainFrame');

const ripplingDuration = const Duration(milliseconds: 250);

Future alfterRippling(Proc()) {
  return new Future.delayed(ripplingDuration, Proc);
}

const listenDur = const Duration(milliseconds: 10);
void listenOn(Element target, String eventType, void proc(Element target)) {
  Timer timer;
  target.on[eventType].listen((event) {
    if (event.target == target) {
      if (timer != null && timer.isActive) timer.cancel();
      timer = new Timer(listenDur, () => proc(target));
    }
  });
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
