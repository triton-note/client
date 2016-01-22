library triton_note.dialog.edit_tide;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:paper_elements/paper_dialog.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/enums.dart';
import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('EditTideDialog');

@Component(
    selector: 'edit-tide-dialog',
    templateUrl: 'packages/triton_note/dialog/edit_tide.html',
    cssUrl: 'packages/triton_note/dialog/edit_tide.css',
    useShadowDom: true)
class EditTideDialog extends AbstractDialog implements ShadowRootAware {
  static const List<Tide> tideList = const [Tide.High, Tide.Flood, Tide.Ebb, Tide.Low];

  @NgOneWayOneTime('setter') set setter(Setter<EditTideDialog> v) => v?.value = this; // Optional
  @NgTwoWay('value') Tide value;

  ShadowRoot _root;
  CachedValue<PaperDialog> _dialog;
  PaperDialog get realDialog => _dialog.value;

  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
    _dialog = new CachedValue(() => _root.querySelector('paper-dialog'));
  }

  changeTide(String name) {
    close();
    final tide = enumByName(Tide.values, name);
    if (tide != null) value = tide;
  }

  List<String> tideNames = new List.unmodifiable(tideList.map((t) => nameOfEnum(t)));
  String tideIcon(String name) => name == null ? null : Tides.iconBy(name);
}
