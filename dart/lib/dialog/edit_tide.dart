library triton_note.dialog.edit_tide;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:paper_elements/paper_dialog.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/enums.dart';

final _logger = new Logger('EditTideDialog');

@Component(
    selector: 'edit-tide-dialog',
    templateUrl: 'packages/triton_note/dialog/edit_tide.html',
    cssUrl: 'packages/triton_note/dialog/edit_tide.css',
    useShadowDom: true)
class EditTideDialog extends ShadowRootAware {
  static const List<Tide> tideList = const [Tide.High, Tide.Flood, Tide.Ebb, Tide.Low];

  @NgOneWay('setter') Setter<EditTideDialog> setter;
  @NgTwoWay('value') Tide value;

  ShadowRoot _root;
  CachedValue<PaperDialog> _dialog;

  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
    _dialog = new CachedValue(() => _root.querySelector('paper-dialog'));
    setter.value = this;
  }

  open() {
    _dialog.value.toggle();
  }

  changeTide(String name) {
    final tide = enumByName(Tide.values, name);
    if (tide != null) value = tide;
    _dialog.value.toggle();
  }

  List<String> get tideNames => tideList.map((t) => nameOfEnum(t));
  String tideIcon(String name) => name == null ? null : Tides.iconBy(name);
  String get tideName => value == null ? null : nameOfEnum(value);
  String get tideImage => tideIcon(tideName);
}
