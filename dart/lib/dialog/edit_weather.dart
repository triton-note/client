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
  TemperatureUnit get _tUnit => CachedPreferences.measures == null ? null : CachedPreferences.measures.temperature;

  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
    _dialog = new CachedValue(() => _root.querySelector('paper-action-dialog'));
  }

  open() {
    _dialog.value.toggle();
  }

  String get temperatureUnit => _tUnit == null ? null : "°${nameOfEnum(_tUnit)[0]}";
  List<String> get weatherNames => Weather.nominalMap.keys;
  String weatherIcon(String nominal) => Weather.nominalMap[nominal];

  Timer _weatherDialogTimer;

  Temperature _temperature;
  int get temperatureValue {
    if (value.temperature == null || _tUnit == null) return null;
    if (_temperature == null) {
      _temperature = value.temperature.convertTo(_tUnit);
    }
    return _temperature.value.round();
  }
  set temperatureValue(int v) {
    if (v == null || _tUnit == null) return;
    if (_temperature != null && _temperature.value == v) return;

    _temperature = new Temperature.fromMap({'value': v.toDouble(), 'unit': nameOfEnum(_tUnit)});
    _logger.fine("Set temperature: ${_temperature.asMap}");
    value.temperature = _temperature;

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
