library triton_note.page.reports_add;

import 'dart:async';
import 'dart:html';
import 'dart:math' as Math;

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_header_panel.dart';
import 'package:core_elements/core_animation.dart';
import 'package:paper_elements/paper_action_dialog.dart';
import 'package:paper_elements/paper_dialog.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/photo.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/upload_session.dart';
import 'package:triton_note/service/photo_shop.dart';
import 'package:triton_note/service/server.dart';
import 'package:triton_note/service/geolocation.dart' as Geo;
import 'package:triton_note/service/googlemaps_browser.dart';
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

  _Catches catches;
  _DateOclock dateOclock;
  _GMap gmap;
  _Conditions conditions;

  bool isReady = false;
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

  int _photoWidth;
  int get photoWidth {
    if (_photoWidth == null) {
      final div = root.querySelector('#photo');
      if (div != null) _photoWidth = div.clientWidth;
    }
    return _photoWidth;
  }
  int get photoHeight => photoWidth == null ? null : (photoWidth * 2 / 3).round();

  AddReportPage(Router router, RouteProvider routeProvider) : super(router) {
    try {
      report.asParam = routeProvider.parameters['report'];
      isReady = true;
    } catch (ex) {
      _logger.info("Adding new report.");
    }
  }

  void onShadowRoot(ShadowRoot sr) {
    super.onShadowRoot(sr);

    catches = new _Catches(root, new GetterSetter(() => report.fishes, (v) => report.fishes = v));
    dateOclock = new _DateOclock(root, new GetterSetter(() => report.dateAt, (v) {
      report.dateAt = v;
      renewConditions();
    }));
    gmap = new _GMap(root, new GetterSetter(() => report.location.name, (v) => report.location.name = v),
        new GetterSetter(() => report.location.geoinfo, (pos) {
      report.location.geoinfo = pos;
    }));
    conditions = new _Conditions(root, new Getter(() => report.condition));
  }

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
      gmap.getMap().then((g) => g.putMarker(report.location.geoinfo));
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

  submit() => rippling(() async {
    _logger.finest("Submitting report: ${report}");
    if (report.location.name == null || report.location.name.isEmpty) report.location.name = "My Spot";
    (await _onSession.future).submit(report);
    back();
  });
}

class UserPreferences {
  static LengthUnit get lengthUnit => LengthUnit.cm;
  static WeightUnit get weightUnit => WeightUnit.kg;
  static TemperatureUnit get temperatureUnit => TemperatureUnit.Cels;
}

class _DateOclock {
  final ShadowRoot _root;
  final GetterSetter<DateTime> _dateAt;

  DateTime tmpDate = new DateTime.now();
  int tmpOclock = 0;

  _DateOclock(this._root, this._dateAt);

  PaperActionDialog _dateDialog;
  PaperActionDialog get dateDialog {
    if (_dateDialog == null) _dateDialog = _root.querySelector('#date-dialog');
    return _dateDialog;
  }

  dialogDate() {
    tmpDate = new DateTime(_dateAt.value.year, _dateAt.value.month, _dateAt.value.day);
    tmpOclock = _dateAt.value.hour;
    dateDialog.toggle();
  }
  commitCalendar() {
    _dateAt.value = new DateTime(tmpDate.year, tmpDate.month, tmpDate.day, tmpOclock);
    _logger.fine("Commit date: ${_dateAt.value}");
  }
}

class _Catches {
  final ShadowRoot _root;
  final GetterSetter<List<Fishes>> list;

  _Catches(this._root, this.list);

  PaperActionDialog _fishDialog;
  PaperActionDialog get fishDialog {
    if (_fishDialog == null) _fishDialog = _root.querySelector('#fish-dialog');
    return _fishDialog;
  }

  String addingFishName;
  int tmpFishIndex;
  Fishes tmpFish;

  // count
  int get tmpFishCount => (tmpFish == null) ? null : tmpFish.count;
  set tmpFishCount(int v) => (tmpFish == null) ? null : tmpFish.count = (v == null || v == 0) ? 1 : v;

  // lenth
  int get tmpFishLength =>
      (tmpFish == null || tmpFish.length == null || tmpFish.length.value == null) ? null : tmpFish.length.value.round();
  set tmpFishLength(int v) =>
      (tmpFish == null || tmpFish.length == null) ? null : tmpFish.length.value = (v == null) ? null : v.toDouble();

  // weight
  int get tmpFishWeight =>
      (tmpFish == null || tmpFish.weight == null || tmpFish.weight.value == null) ? null : tmpFish.weight.value.round();
  set tmpFishWeight(int v) =>
      (tmpFish == null || tmpFish.weight == null) ? null : tmpFish.weight.value = (v == null) ? null : v.toDouble();

  String get lengthUnit => nameOfEnum(UserPreferences.lengthUnit);
  String get weightUnit => nameOfEnum(UserPreferences.weightUnit);

  addFish() {
    if (addingFishName != null && addingFishName.isNotEmpty) {
      final fish = new Fishes.fromMap({'name': addingFishName, 'count': 1});
      addingFishName = null;
      list.value = list.value..add(fish);
    }
  }
  editFish(int index) {
    if (0 <= index && index < list.value.length) {
      final fish = new Fishes.fromMap(new Map.from(list.value[index].asMap));
      if (fish.length == null) fish.length =
          new Length.fromMap({'value': 0, 'unit': nameOfEnum(UserPreferences.lengthUnit)});
      if (fish.weight == null) fish.weight =
          new Weight.fromMap({'value': 0, 'unit': nameOfEnum(UserPreferences.weightUnit)});
      _logger.fine("Editing fish[${index}]: ${fish.asMap}");

      tmpFishIndex = index;
      tmpFish = fish;
      fishDialog.toggle();
    }
  }
  commitFish() {
    _logger.fine("Commit fish: ${tmpFish.asMap}");
    final fish = new Fishes.fromMap(new Map.from(tmpFish.asMap));

    if (fish.length != null && fish.length.value == 0) fish.length = null;
    if (fish.weight != null && fish.weight.value == 0) fish.weight = null;
    _logger.finest("Set fish[${tmpFishIndex}]: ${fish.asMap}");
    list.value = (list.value..[tmpFishIndex] = fish);
  }
  deleteFish() {
    _logger.fine("Deleting fish: ${tmpFishIndex}");
    if (0 <= tmpFishIndex && tmpFishIndex < list.value.length) {
      list.value = list.value..removeAt(tmpFishIndex);
    }
  }
}

class _GMap {
  static const int mapShrinkedHeight = 200;

  final ShadowRoot _root;
  final GetterSetter<String> spotName;
  final GetterSetter<GeoInfo> _geoinfo;

  _GMap(this._root, this.spotName, this._geoinfo);

  DivElement _scroller;
  DivElement get scroller {
    if (_scroller == null) {
      final panel = _root.querySelector('core-header-panel[main]') as CoreHeaderPanel;
      if (panel != null) _scroller = panel.scroller;
    }
    return _scroller;
  }

  bool get isReady => _geoinfo.value != null;

  Future<GoogleMap> _gmap;
  Future<GoogleMap> getMap() async {
    if (_gmap == null && _geoinfo.value != null) {
      final div = _root.querySelector('#google-maps');
      div.style.height = "${mapShrinkedHeight}px";
      _gmap = makeGoogleMap(div, _geoinfo.value)
        ..then((gmap) {
          gmap.onClick = (pos) {
            _logger.fine("Point map: ${pos}");
            _geoinfo.value = pos;
            gmap.clearMarkers();
            gmap.putMarker(pos);
          };
        });
    }
    return _gmap;
  }
  bool mapExpanded = false;

  toggleMap(event) {
    final button = event.target as Element;
    final int buttonHeight = button.getBoundingClientRect().height.round();
    _logger.finest("Toggle map: ${button}(height: ${buttonHeight})");
    alfterRippling(() async {
      final gmap = await getMap();
      if (gmap == null) return;

      final margin = 10;
      final base = _root.querySelector('#input');
      final int curHeight = gmap.hostElement.getBoundingClientRect().height.round();

      scroll(int nextHeight, int move, [int duration = 300]) {
        _logger.info("Animation of map: height: ${curHeight} -> ${nextHeight}, move: ${move}, duration: ${duration}");
        new CoreAnimation()
          ..target = gmap.hostElement
          ..duration = duration
          ..fill = "forwards"
          ..keyframes = [{'height': "${curHeight}px"}, {'height': "${nextHeight}px"}]
          ..play();

        shift(String translation, int duration) => new CoreAnimation()
          ..target = base
          ..duration = duration
          ..fill = "both"
          ..keyframes = [{'transform': "none"}, {'transform': translation}]
          ..play();
        shift("translateY(${-move}px)", duration);

        new Future.delayed(new Duration(milliseconds: (duration * 1.1).round()), () {
          gmap.triggerResize();
          if (move != 0) {
            _logger.finest("Scrolling by ${move}");
            shift("none", 0);
            scroller.scrollTop += move;
          }
        });
      }

      if (mapExpanded) {
        _logger.info("Shrink map: ${gmap}");
        scroll(mapShrinkedHeight, 0);
        mapExpanded = false;
      } else {
        _logger.info("Expand map: ${gmap}");
        final int top = base.getBoundingClientRect().top.round();
        final int curPos = gmap.hostElement.getBoundingClientRect().top.round() - top;
        _logger.finest("Map div pos: ${curPos}");

        scroll(window.innerHeight - top - buttonHeight - margin, Math.max(0, curPos - margin));
        mapExpanded = true;
      }
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
  String tideIcon(String name) => name == null ? null : "/img/tide/${name.toLowerCase()}.png";
  String get tideName => _condition.value.tide == null ? null : nameOfEnum(_condition.value.tide);
  String get tideImage => tideIcon(tideName);
  String get moonImage =>
      _condition.value.moon == null ? null : "/img/moon/phase-${_condition.value.moon.toString().padLeft(2, '0')}.png";
}
