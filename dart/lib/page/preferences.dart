library triton_note.page.preferences;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:paper_elements/paper_toggle_button.dart';

import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/facebook.dart';
import 'package:triton_note/service/preferences.dart';
import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('PreferencesPage');

@Component(
    selector: 'preferences',
    templateUrl: 'packages/triton_note/page/preferences.html',
    cssUrl: 'packages/triton_note/page/preferences.css',
    useShadowDom: true)
class PreferencesPage extends MainPage {
  static const submitDuration = const Duration(seconds: 20);

  Measures measures;
  Timer _submitTimer;

  bool get isReady => measures != null;

  PreferencesPage(Router router) : super(router);

  void onShadowRoot(ShadowRoot sr) {
    super.onShadowRoot(sr);

    toggleButton(String parent) => root.querySelector("${parent} paper-toggle-button") as PaperToggleButton;

    UserPreferences.current.then((c) {
      measures = c.measures;
      new Future.delayed(new Duration(milliseconds: 10), () {
        toggleButton('#unit #length').checked = measures.length == LengthUnit.cm;
        toggleButton('#unit #weight').checked = measures.weight == WeightUnit.g;
        toggleButton('#unit #temperature').checked = measures.temperature == TemperatureUnit.Cels;
      });
    });

    FBConnect.getToken().then((token) {
      new Future.delayed(new Duration(milliseconds: 10), () {
        toggleButton('#social #connection').checked = token != null;
      });
    });
  }

  void detach() {
    super.detach();
    if (_submitTimer != null && _submitTimer.isActive) {
      _submitTimer.cancel();
    }
  }

  void changeLength(event) {
    final toggle = event.target as PaperToggleButton;
    _logger.fine("Toggle Length: ${toggle.checked}");
    measures.length = toggle.checked ? LengthUnit.cm : LengthUnit.inch;
  }

  void changeWeight(event) {
    final toggle = event.target as PaperToggleButton;
    _logger.fine("Toggle Weight: ${toggle.checked}");
    measures.weight = toggle.checked ? WeightUnit.g : WeightUnit.oz;
  }

  void changeTemperature(event) {
    final toggle = event.target as PaperToggleButton;
    _logger.fine("Toggle Temperature: ${toggle.checked}");
    measures.temperature = toggle.checked ? TemperatureUnit.Cels : TemperatureUnit.Fahr;
  }

  changeFacebook(event) async {
    final toggle = event.target as PaperToggleButton;
    _logger.fine(() => "Toggle Facebook: ${toggle.checked}");
    try {
      if (toggle.checked) {
        await FBConnect.login();
      } else {
        await FBConnect.logout();
      }
    } catch (ex) {
      _logger.warning(() => "Error: ${ex}");
    }
    final token = await FBConnect.getToken();
    toggle.checked = token != null;
  }
}
