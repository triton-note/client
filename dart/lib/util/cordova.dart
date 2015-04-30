library cordova;

import 'dart:async';
import 'dart:html';
import 'dart:js';

final bool isCordova = context['device'] != null;

Completer<String> _onDeviceReady;

void onDeviceReady(proc(String)) {
  if (_onDeviceReady == null) {
    _onDeviceReady = new Completer<String>();
    if (isCordova) {
      document.on['deviceready'].listen((event) {
        _onDeviceReady.complete("cordova");
      });
    } else _onDeviceReady.complete("browser");
  }
  _onDeviceReady.future.then(proc);
}

void hideSplashScreen() {
  final splash = context['navigator']['splashscreen'];
  if (splash != null) {
    print("Hide SplashScreen.");
    splash.callMethod('hide', []);
  }
}
