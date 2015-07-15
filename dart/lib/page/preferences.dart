library triton_note.page.preferences;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:paper_elements/paper_toggle_button.dart';

import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/preferences.dart';
import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('PreferencesPage');

@Component(
    selector: 'preferences',
    templateUrl: 'packages/triton_note/page/preferences.html',
    cssUrl: 'packages/triton_note/page/preferences.css',
    useShadowDom: true)
class PreferencesPage extends MainFrame implements DetachAware {
  static const submitDuration = const Duration(seconds: 20);

  Measures measures;
  Timer _submitTimer;

  bool get isReady => measures != null;

  PreferencesPage(Router router) : super(router);

  void onShadowRoot(ShadowRoot sr) {
    super.onShadowRoot(sr);

    UserPreferences.measures.then((v) {
      measures = v;
      new Future.delayed(new Duration(milliseconds: 10), () {
        root.querySelector('#unit #length paper-toggle-button') as PaperToggleButton
          ..checked = v.length == LengthUnit.cm;
        root.querySelector('#unit #weight paper-toggle-button') as PaperToggleButton
          ..checked = v.weight == WeightUnit.kg;
        root.querySelector('#unit #temperature paper-toggle-button') as PaperToggleButton
          ..checked = v.temperature == TemperatureUnit.Cels;
      });
    });
  }

  void detach() {
    if (_submitTimer != null && _submitTimer.isActive) {
      _submitTimer.cancel();
      _update();
    }
  }

  void changeLength(event) {
    final toggle = event.target as PaperToggleButton;
    _logger.fine("Toggle Length: ${toggle.checked}");
    measures.length = toggle.checked ? LengthUnit.cm : LengthUnit.inch;
    _submit();
  }

  void changeWeight(event) {
    final toggle = event.target as PaperToggleButton;
    _logger.fine("Toggle Weight: ${toggle.checked}");
    measures.weight = toggle.checked ? WeightUnit.kg : WeightUnit.pound;
    _submit();
  }

  void changeTemperature(event) {
    final toggle = event.target as PaperToggleButton;
    _logger.fine("Toggle Temperature: ${toggle.checked}");
    measures.temperature = toggle.checked ? TemperatureUnit.Cels : TemperatureUnit.Fahr;
    _submit();
  }

  void _submit() {
    if (_submitTimer != null && _submitTimer.isActive) _submitTimer.cancel();
    _submitTimer = new Timer(submitDuration, _update);
  }

  void _update() {
    _logger.fine("Update preferences");
    UserPreferences.update(measures);
  }
}
