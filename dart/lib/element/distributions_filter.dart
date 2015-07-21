library triton_note.element.distributions_filter;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:paper_elements/paper_radio_group.dart';

import 'package:triton_note/dialog/edit_timestamp.dart';
import 'package:triton_note/service/preferences.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/enums.dart';

final _logger = new Logger('DistributionsFilterElement');

@Component(
    selector: 'distributions-filter',
    templateUrl: 'packages/triton_note/element/distributions_filter.html',
    cssUrl: 'packages/triton_note/element/distributions_filter.css',
    useShadowDom: true)
class DistributionsFilterElement extends ShadowRootAware {
  @NgOneWay('setter') Setter<DistributionsFilterElement> setter;

  ShadowRoot _root;

  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
    setter.value = this;

    _root.querySelector('#term paper-radio-group').on['core-select'].listen((event) {
      final radio = event.target;
      if (radio is PaperRadioGroup) {
        _logger.finest("Term radio selected: ${radio.selected}");
      }
    });
  }

  String get lengthUnit => nameOfEnum(CachedMeasures.lengthUnit);
  String get weightUnit => nameOfEnum(CachedMeasures.weightUnit);

  // size
  int sizeMinLength = 0;
  bool get sizeMinLengthActive => sizeMinLength > 0;
  int sizeMaxLength = 0;
  bool get sizeMaxLengthActive => sizeMaxLength > sizeMinLength;
  bool get sizeLengthActive => sizeMinLengthActive || sizeMaxLengthActive;

  int sizeMinWeight = 0;
  bool get sizeMinWeightActive => sizeMinWeight > 0;
  int sizeMaxWeight = 0;
  bool get sizeMaxWeightActive => sizeMaxWeight > sizeMinWeight;
  bool get sizeWeightActive => sizeMinWeightActive || sizeMaxWeightActive;

  int recentValue;
  String recentUnitName = nameOfEnum(_RecentUnit.values.first);
  _RecentUnit get recentUnit => enumByName(_RecentUnit.values, recentUnitName);
  final List<String> recentUnitList = _RecentUnit.values.map(nameOfEnum);

  int seasonBegin = 1;
  int seasonEnd = 2;

  DateTime termFrom = new DateTime.now();
  Getter<EditTimestampDialog> termFromDialog = new PipeValue();
  DateTime termTo = new DateTime.now();
  Getter<EditTimestampDialog> termToDialog = new PipeValue();
}

enum _RecentUnit { days, weeks, months }
