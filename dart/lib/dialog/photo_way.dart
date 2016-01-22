library triton_note.dialog.photo_way;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:paper_elements/paper_dialog.dart';

import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('PhotoWayDialog');

@Component(selector: 'photo-way-dialog', templateUrl: 'packages/triton_note/dialog/photo_way.html', useShadowDom: true)
class PhotoWayDialog extends AbstractDialog implements ShadowRootAware {
  @NgOneWayOneTime('setter') set setter(Setter<PhotoWayDialog> v) => v?.value = this; // Optional

  ShadowRoot _root;
  CachedValue<PaperDialog> _dialog;
  PaperDialog get realDialog => _dialog.value;

  String message;
  bool take = null;

  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
    _dialog = new CachedValue(() => _root.querySelector('paper-dialog'));
  }

  done(bool v) {
    take = v;
    close();
  }
}
