library triton_note.dialog.edit_fish;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:paper_elements/paper_action_dialog.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/preferences.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/enums.dart';

final _logger = new Logger('EditFishDialog');

@Component(
    selector: 'edit-fish-dialog',
    templateUrl: 'packages/triton_note/dialog/edit_fish.html',
    cssUrl: 'packages/triton_note/dialog/edit_fish.css',
    useShadowDom: true)
class EditFishDialog extends ShadowRootAware {
  @NgOneWay('setter') Setter<EditFishDialog> setter;

  ShadowRoot _root;
  CachedValue<PaperActionDialog> _dialog;

  GetterSetter<Fishes> _original;
  Fishes tmpFish;

  // count
  int get tmpFishCount => (tmpFish == null) ? null : tmpFish.count;
  set tmpFishCount(int v) => (tmpFish == null) ? null : tmpFish.count = (v == null || v == 0) ? 1 : v;

  // lenth
  int get tmpFishLength => (tmpFish == null) ? null : tmpFish.length.value.round();
  set tmpFishLength(int v) => (tmpFish == null) ? null : tmpFish.length.value = (v == null) ? null : v.toDouble();

  // weight
  int get tmpFishWeight => (tmpFish == null) ? null : tmpFish.weight.value.round();
  set tmpFishWeight(int v) => (tmpFish == null) ? null : tmpFish.weight.value = (v == null) ? null : v.toDouble();

  String get lengthUnit => nameOfEnum(UserPreferences.lengthUnit);
  String get weightUnit => nameOfEnum(UserPreferences.weightUnit);

  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
    _dialog = new CachedValue(() => _root.querySelector('paper-action-dialog'));
    setter.value = this;
  }

  open(GetterSetter<Fishes> value) {
    _original = value;
    final fish = new Fishes.fromMap(new Map.from(_original.value.asMap));

    if (fish.count == null || fish.count == 0) fish.count = 1;
    fish.length = (fish.length == null)
        ? new Length.fromMap({'value': 0, 'unit': nameOfEnum(UserPreferences.lengthUnit)})
        : fish.length.convertTo(UserPreferences.lengthUnit);
    fish.weight = (fish.weight == null)
        ? new Weight.fromMap({'value': 0, 'unit': nameOfEnum(UserPreferences.weightUnit)})
        : fish.weight.convertTo(UserPreferences.weightUnit);
    _logger.fine("Editing fish: ${fish.asMap}");

    tmpFish = fish;
    _dialog.value.toggle();
  }

  commit() {
    _logger.fine("Commit fish: ${tmpFish}");
    final fish = new Fishes.fromMap(new Map.from(tmpFish.asMap));

    if (fish.length != null && fish.length.value == 0) fish.length = null;
    if (fish.weight != null && fish.weight.value == 0) fish.weight = null;
    _logger.finest("Set fish: ${fish}");

    _original.value = fish;
  }

  delete() {
    _logger.fine("Deleting fish");
    _original.value = null;
  }
}
