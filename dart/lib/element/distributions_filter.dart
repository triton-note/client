library triton_note.element.distributions_filter;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:paper_elements/paper_radio_group.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/dialog/edit_timestamp.dart';
import 'package:triton_note/dialog/edit_weather.dart';
import 'package:triton_note/dialog/edit_tide.dart';
import 'package:triton_note/service/preferences.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/enums.dart';

final _logger = new Logger('DistributionsFilterElement');

const _selectDur = const Duration(milliseconds: 10);

@Component(
    selector: 'distributions-filter',
    templateUrl: 'packages/triton_note/element/distributions_filter.html',
    cssUrl: 'packages/triton_note/element/distributions_filter.css',
    useShadowDom: true)
class DistributionsFilterElement extends ShadowRootAware {
  @NgOneWay('setter') Setter<DistributionsFilterElement> setter;

  ShadowRoot _root;
  _FishKind kind;
  _FishSize size;
  _Conditions cond;
  _Term term;

  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
    setter.value = this;

    kind = new _FishKind(_root);
    size = new _FishSize(_root);
    cond = new _Conditions(_root);
    term = new _Term(_root);
  }
}

enum _RecentUnit { days, weeks, months }

class _FishKind {
  final ShadowRoot _root;

  String name;

  _FishKind(this._root);
}

class _FishSize {
  final ShadowRoot _root;

  _FishSize(this._root);

  String get lengthUnit => nameOfEnum(CachedMeasures.lengthUnit);
  String get weightUnit => nameOfEnum(CachedMeasures.weightUnit);

  int lengthMin = 0;
  bool get lengthMinActive => lengthMin > 0;
  int lengthMax = 0;
  bool get lengthMaxActive => lengthMax > lengthMin;
  bool get lengthActive => lengthMinActive || lengthMaxActive;

  int weightMin = 0;
  bool get weightMinActive => weightMin > 0;
  int weightMax = 0;
  bool get weightMaxActive => weightMax > weightMin;
  bool get weightActive => weightMinActive || weightMaxActive;
}

class _Conditions {
  final ShadowRoot _root;

  Weather weather;
  int temperatureMin, temperatureMax;

  Tide tide;
  String get tideName => nameOfEnum(tide);
  String get tideIcon => Tides.iconOf(tide);

  int moon;
  Getter<EditWeatherDialog> weatherDialog = new PipeValue();
  Getter<EditTideDialog> tideDialog = new PipeValue();

  _Conditions(this._root);
}

class _Term {
  final ShadowRoot _root;

  _Term(this._root) {
    Timer timer;
    _root.querySelector('#term paper-radio-group').on['core-select'].listen((event) {
      final radio = event.target;
      if (radio is PaperRadioGroup) {
        if (timer != null && timer.isActive) timer.cancel();
        timer = new Timer(_selectDur, () {
          _logger.finest("Term radio selected: ${radio.selected}");
        });
      }
    });
  }

  int recentValue;
  String recentUnitName = nameOfEnum(_RecentUnit.values.first);
  _RecentUnit get recentUnit => enumByName(_RecentUnit.values, recentUnitName);
  final List<String> recentUnitList = _RecentUnit.values.map(nameOfEnum);

  int seasonBegin = 1;
  int seasonEnd = 2;

  DateTime intervalFrom = new DateTime.now();
  Getter<EditTimestampDialog> intervalFromDialog = new PipeValue();
  DateTime intervalTo = new DateTime.now();
  Getter<EditTimestampDialog> intervalToDialog = new PipeValue();
}
