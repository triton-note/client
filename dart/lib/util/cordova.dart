library cordova;

import 'dart:async';
import 'dart:html';
import 'dart:js';

final bool isCordova = window.location.protocol == "file:";

final Completer<String> _onDeviceReady = new Completer<String>();
bool get isDeviceReady => _onDeviceReady.isCompleted;

bool _initialized = false;
void _initialize() {
  if (isCordova) {
    document.on['deviceready'].listen((event) {
      _onDeviceReady.complete("cordova");
    });
  } else _onDeviceReady.complete("browser");
  _initialized = true;
}

void onDeviceReady(void proc(String)) {
  if (!_initialized) _initialize();
  _onDeviceReady.future.then(proc);
}

void hideSplashScreen() {
  final splash = context['navigator']['splashscreen'];
  if (splash != null) {
    print("Hide SplashScreen.");
    splash.callMethod('hide', []);
  }
}
