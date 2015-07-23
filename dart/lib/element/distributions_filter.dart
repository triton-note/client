library triton_note.element.distributions_filter;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:paper_elements/paper_checkbox.dart';
import 'package:paper_elements/paper_toggle_button.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/dialog/edit_timestamp.dart';
import 'package:triton_note/dialog/edit_weather.dart';
import 'package:triton_note/dialog/edit_tide.dart';
import 'package:triton_note/service/preferences.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/enums.dart';
import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('DistributionsFilterElement');

@Component(
    selector: 'distributions-filter',
    templateUrl: 'packages/triton_note/element/distributions_filter.html',
    cssUrl: 'packages/triton_note/element/distributions_filter.css',
    useShadowDom: true)
class DistributionsFilterElement extends ShadowRootAware {
  @NgOneWayOneTime('setter') set setter(Setter<DistributionsFilterElement> v) => v == null ? null : v.value = this;

  ShadowRoot _root;
  Getter<bool> _includeOthers;
  _Fish fish;
  _Conditions cond;
  _Term term;

  bool get isIncludeOthers => _includeOthers == null ? null : _includeOthers.value;

  void onShadowRoot(ShadowRoot sr) {
    _root = sr;

    _includeOthers =
        new Getter(() => (_root.querySelector('#only-mine paper-toggle-button') as PaperToggleButton).checked);

    fish = new _Fish(_root);
    cond = new _Conditions(_root);
    term = new _Term(_root);
  }
}

enum _RecentUnit { days, weeks, months }

abstract class _FilterParams {
  final String id;
  final ShadowRoot _root;
  final Map<String, PaperCheckbox> _checkboxes = {};

  _FilterParams(this.id, this._root) {
    _root.querySelectorAll("#${id} core-label>paper-checkbox").forEach((box) {
      _checkboxes[box.parent.parent.id] = box;
    });
  }

  bool isActive(String name) => _checkboxes[name] == null ? false : _checkboxes[name].checked;

  PaperCheckbox _checkboxListen(String name, void proc(PaperCheckbox box)) {
    final box = _checkboxes[name];
    listenOn(box, 'change', (event) {
      proc(box);
    });
    return box;
  }
}

class _Fish extends _FilterParams {
  _Fish(ShadowRoot root) : super('fish', root);

  String name;
  int lengthMin = 0;
  int lengthMax = 0;
  int weightMin = 0;
  int weightMax = 0;

  String get lengthUnit => nameOfEnum(CachedMeasures.lengthUnit);
  String get weightUnit => nameOfEnum(CachedMeasures.weightUnit);

  bool get isActiveName => isActive('name') && name != null && name.isNotEmpty;

  bool get isActiveLengthMin => lengthMin > 0;
  bool get isActiveLengthMax => lengthMax > lengthMin;
  bool get isActiveLength => isActive('length') && (isActiveLengthMin || isActiveLengthMax);

  bool get isActiveWeightMin => weightMin > 0;
  bool get isActiveWeightMax => weightMax > weightMin;
  bool get isActiveWeight => isActive('weight') && (isActiveWeightMin || isActiveWeightMax);
}

class _Conditions extends _FilterParams {
  _Conditions(ShadowRoot root) : super('condition', root);

  String get temperatureUnit =>
      CachedMeasures.temperatureUnit == null ? null : "°${nameOfEnum(CachedMeasures.temperatureUnit)[0]}";

  Weather weather = new Weather.fromMap({'nominal': 'Clear', 'iconUrl': Weather.nominalMap['Clear']});
  int temperatureMin, temperatureMax;
  bool get isActiveTemperatureMin => temperatureMin != null && 0 < temperatureMin;
  bool get isActiveTemperatureMax =>
      temperatureMax != null && (temperatureMin == null ? 0 : temperatureMin) < temperatureMax;

  Tide tide = Tide.Flood;
  String get tideName => nameOfEnum(tide);
  String get tideIcon => Tides.iconOf(tide);

  int moon;
  Getter<EditWeatherDialog> weatherDialog = new PipeValue();
  Getter<EditTideDialog> tideDialog = new PipeValue();

  bool get isActiveWeather => isActive('weather') && weather.nominal != null;
  bool get isActiveTemperature => isActive('temperature') && (isActiveTemperatureMin || isActiveTemperatureMax);
  bool get isActiveTide => isActive('tide') && tideName != null;
}

class _Term extends _FilterParams {
  _Term(ShadowRoot root) : super('term', root) {
    ['interval', 'recent', 'season'].forEach((name) {
      _checkboxListen(name, (box) {
        if (box.checked) {
          _checkboxes.values.forEach((a) => a.checked = false);
          box.checked = true;
        }
      });
    });
  }

  bool get isActiveInterval => isActive('interval');
  bool get isActiveRecent => isActive('recent') && recentValue != null && recentValue > 0;
  bool get isActiveSeason => isActive('season');

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
