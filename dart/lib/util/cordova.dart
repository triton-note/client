library cordova;

import 'dart:html';

import 'package:triton_note/util/after_done.dart';

class Cordova {
  static final bool isCordova = window.location.protocol == "file:";

  static final AfterDone<String> _onReady = new AfterDone<String>("Cordova deviceready");
  
  static bool get isReady => _onReady.isDone;
  
  static void initialize() {
    if (isCordova) {
      document.on['deviceready'].listen((event) {
        _onReady.done("cordova");
      });
    } else _onReady.done("browser");;
  }
  
  static void onReady(void proc(String)) => _onReady.listen(proc);
}
