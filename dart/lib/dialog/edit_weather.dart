library triton_note.dialog.edit_weather;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:paper_elements/paper_action_dialog.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/preferences.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/enums.dart';

final _logger = new Logger('EditWeatherDialog');

@Component(
    selector: 'edit-weather-dialog',
    templateUrl: 'packages/triton_note/dialog/edit_weather.html',
    cssUrl: 'packages/triton_note/dialog/edit_weather.css',
    useShadowDom: true)
class EditWeatherDialog extends ShadowRootAware {
  @NgOneWayOneTime('setter') set setter(Setter<EditWeatherDialog> v) => v == null ? null : v.value = this;
  @NgOneWay('value') Weather value;
  @NgAttr('without-temperature') String withoutTemperature;

  ShadowRoot _root;
  bool get withTemperature => withoutTemperature == null || withoutTemperature.toLowerCase() == "false";
  CachedValue<PaperActionDialog> _dialog;
  TemperatureUnit _tUnit;

  EditWeatherDialog() {
    UserPreferences.current.then((c) => _tUnit = c.measures.temperature);
  }

  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
    _dialog = new CachedValue(() => _root.querySelector('paper-action-dialog'));
  }

  open() {
    _dialog.value.toggle();
  }

  String get temperatureUnit => _tUnit == null ? null : "°${nameOfEnum(_tUnit)[0]}";
  final List<String> weatherNames = new List.unmodifiable(Weather.nominalMap.keys);
  String weatherIcon(String nominal) => Weather.nominalMap[nominal];

  Timer _weatherDialogTimer;

  int _temperatureValue;
  int get temperatureValue {
    if (value.temperature == null || _tUnit == null) return null;
    if (_temperatureValue == null) {
      _temperatureValue = value.temperature.convertTo(_tUnit).value.round();
    }
    return _temperatureValue;
  }
  set temperatureValue(int v) {
    if (v == null || _tUnit == null) return;
    if (_temperatureValue == v) return;

    _temperatureValue = v;
    value.temperature = new Temperature.of(_tUnit, v);
    _logger.fine("Set temperature: ${value.temperature}");

    _logger.finest("Setting timer for closing weather dialog.");
    if (_weatherDialogTimer != null) _weatherDialogTimer.cancel();
    _weatherDialogTimer = new Timer(new Duration(seconds: 3), () {
      if (_dialog.value.opened) _dialog.value.toggle();
    });
  }

  changeWeather(String nominal) {
    value.nominal = nominal;
    value.iconUrl = weatherIcon(nominal);
  }
}
