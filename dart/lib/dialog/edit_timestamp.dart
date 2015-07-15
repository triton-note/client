library triton_note.dialog.edit_timestamp;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:paper_elements/paper_action_dialog.dart';

import 'package:triton_note/util/getter_setter.dart';

final _logger = new Logger('EditTimestampDialog');

@Component(
    selector: 'edit-timestamp-dialog',
    templateUrl: 'packages/triton_note/dialog/edit_timestamp.html',
    cssUrl: 'packages/triton_note/dialog/edit_timestamp.css',
    useShadowDom: true)
class EditTimestampDialog extends ShadowRootAware {
  @NgTwoWay('value') DateTime value;
  @NgOneWay('setter') Setter<EditTimestampDialog> setter;

  ShadowRoot _root;
  int tmpOclock = 0;
  DateTime tmpDate = new DateTime.now();

  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
    setter.value = this;
  }

  toggle() {
    value = value.toLocal();
    tmpOclock = value.hour;
    tmpDate = new DateTime(value.year, value.month, value.day);
    _root.querySelector('paper-action-dialog#timestamp-dialog') as PaperActionDialog..toggle();
  }

  commit() {
    value = new DateTime(tmpDate.year, tmpDate.month, tmpDate.day, tmpOclock);
  }
}
