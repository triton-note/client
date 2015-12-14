library triton_note.dialog.alert;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:paper_elements/paper_dialog.dart';

import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('AlertDialog');

@Component(
    selector: 'alert-dialog',
    templateUrl: 'packages/triton_note/dialog/alert.html',
    cssUrl: 'packages/triton_note/dialog/alert.css',
    useShadowDom: true)
class AlertDialog extends MainDialog implements ShadowRootAware {
  @NgOneWayOneTime('setter') set setter(Setter<AlertDialog> v) => v == null ? null : v.value = this;

  ShadowRoot _root;
  CachedValue<PaperDialog> _dialog;
  PaperDialog get realDialog => _dialog.value;

  String message;

  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
    _dialog = new CachedValue(() => _root.querySelector('paper-dialog'));
  }
}
