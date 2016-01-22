library triton_note.dialog.geolocation;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:paper_elements/paper_dialog.dart';

import 'package:triton_note/service/geolocation.dart';
import 'package:triton_note/util/cordova.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('GeolocationDialog');

@Component(
    selector: 'geolocation-dialog',
    templateUrl: 'packages/triton_note/dialog/geolocation.html',
    cssUrl: 'packages/triton_note/dialog/geolocation.css',
    useShadowDom: true)
class GeolocationDialog extends AbstractDialog implements ShadowRootAware {
  @NgOneWayOneTime('setter') set setter(Setter<GeolocationDialog> v) => v?.value = this; // Optional
  @NgAttr('message') String message;

  CachedValue<PaperDialog> _dialog;
  PaperDialog get realDialog => _dialog.value;

  bool get canSetting => isAndroid;

  void onShadowRoot(ShadowRoot sr) {
    _dialog = new CachedValue(() => sr.querySelector('paper-dialog'));
  }

  setting() => switchToLocationSettings();
}
