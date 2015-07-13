library triton_note.page.reports_add;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_header_panel.dart';
import 'package:core_elements/core_animation.dart';
import 'package:paper_elements/paper_dialog.dart';

import 'package:triton_note/dialog/edit_fish.dart';
import 'package:triton_note/dialog/edit_timestamp.dart';
import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/photo.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/upload_session.dart';
import 'package:triton_note/service/photo_shop.dart';
import 'package:triton_note/service/server.dart';
import 'package:triton_note/service/geolocation.dart' as Geo;
import 'package:triton_note/service/googlemaps_browser.dart';
import 'package:triton_note/service/preferences.dart';
import 'package:triton_note/util/enums.dart';
import 'package:triton_note/util/main_frame.dart';
import 'package:triton_note/util/getter_setter.dart';

final _logger = new Logger('AddReportPage');

@Component(
    selector: 'add-report',
    templateUrl: 'packages/triton_note/page/add_report.html',
    cssUrl: 'packages/triton_note/page/add_report.css',
    useShadowDom: true)
class AddReportPage extends MainFrame {
  final Completer<UploadSession> _onSession = new Completer();
  final Report report =
      new Report.fromMap({'id': '', 'userId': '', 'fishes': [], 'location': {}, 'condition': {'weather': {}}});

  final PipeValue<EditTimestampDialog> dateOclock = new PipeValue();
  final PipeValue<EditFishDialog> fishDialog = new PipeValue();

  _GMap gmap;
  _Conditions conditions;

  bool isReady = false;

  AddReportPage(Router router, RouteProvider routeProvider) : super(router) {
    try {
      report.asParam = routeProvider.parameters['report'];
      isReady = true;
    } catch (ex) {
      _logger.info("Adding new report.");
    }
  }

  @override
  void onShadowRoot(ShadowRoot sr) {
    super.onShadowRoot(sr);

    gmap = new _GMap(root, new GetterSetter(() => report.location.name, (v) => report.location.name = v),
        new GetterSetter(() => report.location.geoinfo, (pos) {
      report.location.geoinfo = pos;
    }));
    conditions = new _Conditions(root, new Getter(() => report.condition));
  }

  /**
   * Choosing photo and get conditions and inference.
   */
  choosePhoto(bool take) => rippling(() {
    final shop = new PhotoShop(take);
    isReady = true;

    shop.photoUrl.then((url) {
      report.photo = new Photo.fromMap({'reduced': {'mainview': {'url': url}}});
    });

    shop.photo.then((photo) async {
      final session = new UploadSession(photo);
      _onSession.complete(session);

      session.photo.then((v) async {
        report.photo = v;
        submitable();
      });

      try {
        report.dateAt = await shop.timestamp;
      } catch (ex) {
        _logger.info("No Timestamp in Exif: ${ex}");
        report.dateAt = new DateTime.now();
      }

      try {
        report.location.geoinfo = await shop.geoinfo;
      } catch (ex) {
        _logger.info("No GeoInfo in Exif: ${ex}");
        try {
          report.location.geoinfo = await Geo.location();
        } catch (ex) {
          _logger.info("Failed to get current location: ${ex}");
          report.location.geoinfo = new GeoInfo.fromMap({'latitude': 37.971751, 'longitude': 23.726720});
        }
      }
      renewConditions();

      try {
        final inference = await session.infer(report.location.geoinfo, report.dateAt);
        if (inference != null) {
          if (inference.spotName != null && inference.spotName.length > 0) {
            report.location.name = inference.spotName;
          }
          if (inference.fishes != null && inference.fishes.length > 0) {
            if (report.fishes == null) report.fishes = inference.fishes;
            else report.fishes.addAll(inference.fishes);
          }
        }
      } catch (ex) {
        _logger.info("Failed to infer: ${ex}");
      }
    });
  });

  /**
   * Refresh conditions, on changing location or timestamp.
   */
  renewConditions() async {
    try {
      _logger.finest("Getting conditions by report info: ${report}");
      if (report.dateAt != null && report.location.geoinfo != null) {
        final cond = await Server.getConditions(report.dateAt, report.location.geoinfo);
        _logger.fine("Get conditions: ${cond}");
        if (cond.weather == null) {
          cond.weather = new Weather.fromMap({
            'nominal': 'Clear',
            'iconUrl': conditions.weatherIcon('Clear'),
            'temperature': {'value': 20, 'unit': 'Cels'}
          });
        }
        report.condition = cond;
      }
    } catch (ex) {
      _logger.info("Failed to get conditions: ${ex}");
    }
  }

  //********************************
  // Photo View Size

  int _photoWidth;
  int get photoWidth {
    if (_photoWidth == null) {
      final div = root.querySelector('#photo');
      if (div != null) _photoWidth = div.clientWidth;
    }
    return _photoWidth;
  }
  int get photoHeight => photoWidth == null ? null : (photoWidth * 2 / 3).round();

  //********************************
  // Edit Catches

  String addingFishName;

  addFish() {
    if (addingFishName != null && addingFishName.isNotEmpty) {
      final fish = new Fishes.fromMap({'name': addingFishName, 'count': 1});
      addingFishName = null;
      report.fishes = report.fishes..add(fish);
    }
  }

  editFish(int index) {
    if (0 <= index && index < report.fishes.length) {
      fishDialog.value.open(new GetterSetter(() => report.fishes[index], (v) {
        if (v == null) {
          report.fishes = report.fishes..removeAt(index);
        } else {
          report.fishes = report.fishes..[index] = v;
        }
      }));
    }
  }

  //********************************
  // Submit

  void submitable() {
    final div = root.querySelector('core-toolbar div.submit');
    _logger.fine("Appearing submit button: ${div}");
    div.style.display = "block";
    new CoreAnimation()
      ..target = div
      ..duration = 300
      ..fill = "both"
      ..keyframes = [{'transform': "translate(-500px, 100px)", 'opacity': '0'}, {'transform': "none", 'opacity': '1'}]
      ..play();
  }

  submit() => rippling(() async {
    _logger.finest("Submitting report: ${report}");
    if (report.location.name == null || report.location.name.isEmpty) report.location.name = "My Spot";
    (await _onSession.future).submit(report);
    back();
  });
}

class _GMap {
  final ShadowRoot _root;
  final GetterSetter<String> spotName;
  final GetterSetter<GeoInfo> _geoinfo;
  GeoInfo get geoinfo => _geoinfo.value;
  Getter<Element> getScroller;
  Getter<Element> getBase;
  Setter<GoogleMap> setGMap;
  GoogleMap _gmap;

  _GMap(this._root, this.spotName, this._geoinfo) {
    getBase = new Getter<Element>(() => _root.querySelector('#input'));
    getScroller = new Getter<Element>(() {
      final panel = _root.querySelector('core-header-panel[main]') as CoreHeaderPanel;
      return (panel == null) ? null : panel.scroller;
    });
    setGMap = new Setter<GoogleMap>((v) {
      _gmap = v;
      _gmap.putMarker(_geoinfo.value);
      _gmap.onClick = (pos) {
        _logger.fine("Point map: ${pos}");
        _geoinfo.value = pos;
        _gmap.clearMarkers();
        _gmap.putMarker(pos);
      };
    });
  }
}

class _Conditions {
  static const List<Tide> tideList = const [Tide.High, Tide.Flood, Tide.Ebb, Tide.Low];

  final ShadowRoot _root;
  final Getter<Condition> _condition;

  _Conditions(this._root, this._condition);

  PaperDialog _tideDialog;
  PaperDialog get tideDialog {
    if (_tideDialog == null) _tideDialog = _root.querySelector('#tide-dialog');
    return _tideDialog;
  }
  PaperDialog _weatherDialog;
  PaperDialog get weatherDialog {
    if (_weatherDialog == null) _weatherDialog = _root.querySelector('#weather-dialog');
    return _weatherDialog;
  }

  Weather get weather => _condition.value.weather;
  Tide get tide => _condition.value.tide;
  int get moon => _condition.value.moon;

  dialogTide() => tideDialog.toggle();
  changeTide(String name) {
    final tide = enumByName(Tide.values, name);
    if (tide != null) _condition.value.tide = tide;
    tideDialog.toggle();
  }

  dialogWeather() => weatherDialog.toggle();
  changeWeather(String nominal) {
    _condition.value.weather.nominal = nominal;
    _condition.value.weather.iconUrl = weatherIcon(nominal);
    weatherDialog.toggle();
  }

  String get temperatureUnit => "°${nameOfEnum(UserPreferences.temperatureUnit)[0]}";

  Timer _weatherDialogTimer;
  Temperature _temperature;
  int get temperatureValue {
    if (_condition.value.weather.temperature == null) return null;
    if (_temperature == null) _temperature =
        _condition.value.weather.temperature.convertTo(UserPreferences.temperatureUnit);
    return _temperature.value.round();
  }
  set temperatureValue(int v) {
    _temperature =
        new Temperature.fromMap({'value': v.toDouble(), 'unit': nameOfEnum(UserPreferences.temperatureUnit)});
    _logger.fine("Set temperature: ${_temperature.asMap}");
    _condition.value.weather.temperature = _temperature;
    _logger.finest("Setting timer for closing weather dialog.");
    if (_weatherDialogTimer != null) _weatherDialogTimer.cancel();
    _weatherDialogTimer = new Timer(new Duration(seconds: 3), () {
      if (weatherDialog.opened) weatherDialog.toggle();
    });
  }
  List<String> get weatherNames => Weather.nominalMap.keys;
  String weatherIcon(String nominal) => Weather.nominalMap[nominal];

  List<String> get tideNames => tideList.map((t) => nameOfEnum(t));
  String tideIcon(String name) => name == null ? null : Tides.iconBy(name);
  String get tideName => _condition.value.tide == null ? null : nameOfEnum(_condition.value.tide);
  String get tideImage => tideIcon(tideName);
  String get moonImage => _condition.value.moon == null ? null : MoonPhases.iconOf(_condition.value.moon);
}
