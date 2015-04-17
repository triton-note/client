library cordova;

import 'dart:html';

import 'package:triton_note/util/after_done.dart';

final bool isCordova = window.location.protocol == "file:";

final AfterDone<String> _onDeviceReady = new AfterDone<String>("Cordova deviceready");
bool get isDeviceReady => _onDeviceReady.isDone;

bool _initialized = false;
void _initialize() {
  if (isCordova) {
    document.on['deviceready'].listen((event) {
      _onDeviceReady.done("cordova");
    });
  } else _onDeviceReady.done("browser");
  _initialized = true;
}

void onDeviceReady(void proc(String)) {
  if (!_initialized) _initialize();
  _onDeviceReady.listen(proc);
}
