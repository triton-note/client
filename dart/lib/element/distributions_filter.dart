library triton_note.element.distributions_filter;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:paper_elements/paper_checkbox.dart';
import 'package:paper_elements/paper_toggle_button.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/dialog/edit_timestamp.dart';
import 'package:triton_note/dialog/edit_weather.dart';
import 'package:triton_note/dialog/edit_tide.dart';
import 'package:triton_note/service/preferences.dart';
import 'package:triton_note/util/distributions_filters.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/enums.dart';
import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('DistributionsFilterElement');

@Component(
    selector: 'distributions-filter',
    templateUrl: 'packages/triton_note/element/distributions_filter.html',
    cssUrl: 'packages/triton_note/element/distributions_filter.css',
    useShadowDom: true)
class DistributionsFilterElement extends ShadowRootAware with DistributionsFilter {
  @NgOneWayOneTime('setter') set setter(Setter<DistributionsFilterElement> v) => v?.value = this; // Optional

  ShadowRoot _root;
  Getter<bool> _includeOthers;
  _Fish _fish;
  _Conditions _cond;
  _Term _term;

  bool get isIncludeOthers => _includeOthers == null ? null : _includeOthers.value;
  DistributionsFilter_Fish get fish => _fish;
  DistributionsFilter_Conditions get cond => _cond;
  DistributionsFilter_Term get term => _term;

  void onShadowRoot(ShadowRoot sr) {
    _root = sr;

    _includeOthers =
        new Getter(() => (_root.querySelector('#only-mine paper-toggle-button') as PaperToggleButton).checked);

    _fish = new _Fish(_root);
    _cond = new _Conditions(_root);
    _term = new _Term(_root);
  }
}

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
    listenOn(box, 'change', proc);
    return box;
  }
}

class _Fish extends _FilterParams with DistributionsFilter_Fish {
  _Fish(ShadowRoot root) : super('fish', root) {
    UserPreferences.current.then((c) => preferences = c);
  }
  UserPreferences preferences;

  String name;
  int lengthMinValue = 0;
  int lengthMaxValue = 0;
  int weightMinValue = 0;
  int weightMaxValue = 0;

  LengthUnit get _lengthUnit => preferences == null ? null : preferences.measures.length;
  WeightUnit get _weightUnit => preferences == null ? null : preferences.measures.weight;

  double get lengthMin => Length.convertToStandard(_lengthUnit, lengthMinValue);
  double get lengthMax => Length.convertToStandard(_lengthUnit, lengthMaxValue);
  double get weightMin => Weight.convertToStandard(_weightUnit, weightMinValue);
  double get weightMax => Weight.convertToStandard(_weightUnit, weightMaxValue);

  String get lengthUnitName => _lengthUnit == null ? null : nameOfEnum(_lengthUnit);
  String get weightUnitName => _weightUnit == null ? null : nameOfEnum(_weightUnit);

  bool get isActiveName => isActive('name') && name != null && name.isNotEmpty;

  bool get isActiveLengthMin => lengthMin > 0;
  bool get isActiveLengthMax => lengthMax > lengthMin;
  bool get isActiveLength => isActive('length') && (isActiveLengthMin || isActiveLengthMax);

  bool get isActiveWeightMin => weightMin > 0;
  bool get isActiveWeightMax => weightMax > weightMin;
  bool get isActiveWeight => isActive('weight') && (isActiveWeightMin || isActiveWeightMax);
}

class _Conditions extends _FilterParams with DistributionsFilter_Conditions {
  _Conditions(ShadowRoot root) : super('condition', root) {
    UserPreferences.current.then((c) => preferences = c);
  }
  UserPreferences preferences;

  TemperatureUnit get _temperatureUnit => preferences == null ? null : preferences.measures.temperature;
  String get temperatureUnitName => _temperatureUnit == null ? null : "°${nameOfEnum(_temperatureUnit)[0]}";

  Weather weather = new Weather.fromMap({'nominal': 'Clear', 'iconUrl': Weather.nominalMap['Clear']});
  String get weatherNominal => weather.nominal;

  int temperatureMinValue, temperatureMaxValue;

  double get temperatureMin => Temperature.convertToStandard(_temperatureUnit, temperatureMinValue);
  double get temperatureMax => Temperature.convertToStandard(_temperatureUnit, temperatureMaxValue);

  bool get isActiveTemperatureMin => temperatureMinValue != null;
  bool get isActiveTemperatureMax =>
      temperatureMaxValue != null && (temperatureMinValue == null || temperatureMinValue < temperatureMaxValue);

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

class _Term extends _FilterParams with DistributionsFilter_Term {
  static const List<String> _nameOfMonths = const [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "June",
    "July",
    "Aug",
    "Sept",
    "Oct",
    "Nov",
    "Dec"
  ];

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
  bool get isActiveSeason => isActive('season') && seasonBegin > 0 && seasonEnd > 0;

  int recentValue;
  String recentUnitName = nameOfEnum(DistributionsFilter_Term_RecentUnit.values.first);
  DistributionsFilter_Term_RecentUnit get recentUnit =>
      enumByName(DistributionsFilter_Term_RecentUnit.values, recentUnitName);
  final List<String> recentUnitList = DistributionsFilter_Term_RecentUnit.values.map(nameOfEnum);

  List<String> get nameOfMonths => _nameOfMonths;
  int seasonBegin = 1;
  String get seasonBeginMonth => _nameOfMonths[seasonBegin - 1];
  set seasonBeginMonth(String v) => seasonBegin = _nameOfMonths.indexOf(v) + 1;
  int seasonEnd = 12;
  String get seasonEndMonth => _nameOfMonths[seasonEnd - 1];
  set seasonEndMonth(String v) => seasonEnd = _nameOfMonths.indexOf(v) + 1;

  DateTime intervalFrom = new DateTime.now();
  Getter<EditTimestampDialog> intervalFromDialog = new PipeValue();
  DateTime intervalTo = new DateTime.now();
  Getter<EditTimestampDialog> intervalToDialog = new PipeValue();
}
