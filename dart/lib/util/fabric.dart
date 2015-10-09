library triton_note.util.fabric;

import 'dart:js';

class FabricCrashlytics {
  static log(msg) {
    context['plugin']['Fabric']['Crashlytics'].callMethod('log', ["${msg}"]);
  }

  static logException(msg) {
    context['plugin']['Fabric']['Crashlytics'].callMethod('logException', ["${msg}"]);
  }
}

class FabricAnswers {
  static eventLogin({String method: null, bool success: null, Map<String, String> custom: null}) {
    context['plugin']['Fabric']['Answers'].callMethod('eventLogin', [
      new JsObject.jsify({"method": method, "success": success, "custom": custom})
    ]);
  }
}
