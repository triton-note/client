library triton_note.dialog.confirm;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:paper_elements/paper_dialog.dart';

import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('ConfirmDialog');

@Component(
    selector: 'confirm-dialog',
    templateUrl: 'packages/triton_note/dialog/confirm.html',
    cssUrl: 'packages/triton_note/dialog/confirm.css',
    useShadowDom: true)
class ConfirmDialog extends AbstractDialog implements ShadowRootAware {
  @NgOneWayOneTime('setter') set setter(Setter<ConfirmDialog> v) => v == null ? null : v.value = this;

  ShadowRoot _root;
  CachedValue<PaperDialog> _dialog;
  PaperDialog get realDialog => _dialog.value;

  String message;
  bool result = false;

  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
    _dialog = new CachedValue(() => _root.querySelector('paper-dialog'));
  }

  done(bool v) {
    result = v;
    close();
  }
}
