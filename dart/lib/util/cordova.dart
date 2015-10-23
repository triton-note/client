library triton_note.util.cordova;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:logging/logging.dart';

final _logger = new Logger('Cordova');

final bool isCordova = window.location.protocol == "file:";

Completer<String> _onDeviceReady;

void onDeviceReady(proc(String)) {
  window.alert("Entered: onDeviceReady");
  if (_onDeviceReady == null) {
    window.alert("Creating Completer for _onDeviceReady");
    _onDeviceReady = new Completer<String>();
    if (isCordova) {
      window.alert("Listening to deviceready");
      document.on['deviceready'].listen((event) {
        _onDeviceReady.complete("cordova");
        hideStatusBar();
      });
    } else _onDeviceReady.complete("browser");
  }
  window.alert("Setting future to proc");
  _onDeviceReady.future.then(proc);
}

void hideSplashScreen() {
  final splash = context['navigator']['splashscreen'];
  if (splash != null) {
    _logger.info("Hide SplashScreen.");
    splash.callMethod('hide', []);
  }
}

void hideStatusBar() {
  final bar = context['StatusBar'];
  if (bar != null) {
    _logger.info("Hide StatusBar");
    bar.callMethod('hide', []);
  }
}

String get platformName => context['device']['platform'];
bool get isAndroid => platformName == "Android";
