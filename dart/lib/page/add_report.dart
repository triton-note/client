library triton_note.page.reports_add;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
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

final _logger = new Logger('AddReportPage');

@Component(
    selector: 'add-report',
    templateUrl: 'packages/triton_note/page/add_report.html',
    cssUrl: 'packages/triton_note/page/add_report.css',
    useShadowDom: true)
class AddReportPage extends MainFrame implements ShadowRootAware {
  static const List<Tide> tideList = const [Tide.High, Tide.Flood, Tide.Ebb, Tide.Low];

  ShadowRoot _shadowRoot;

  final Completer<UploadSession> _onSession = new Completer();
  final Report report = new Report.fromMap({'location': {}, 'condition': {'weather': {}}});

  String get temperatureUnit => report.condition.weather.temperature == null
      ? null
      : "°${nameOfEnum(report.condition.weather.temperature.unit)[0]}";
  Timer _weatherDialogTimer;
  int get temperatureValue =>
      report.condition.weather.temperature == null ? null : report.condition.weather.temperature.value.round();
  set temperatureValue(int v) {
    report.condition.weather.temperature.value = v.toDouble();
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
  String get tideName => report.condition.tide == null ? null : nameOfEnum(report.condition.tide);
  String get tideImage => tideIcon(tideName);
  String get moonImage =>
      report.condition.moon == null ? null : "/img/moon/phase-${report.condition.moon.toString().padLeft(2, '0')}.png";

  DateTime tmpDate = new DateTime.now();
  int tmpOclock = 0;

  bool isReady = false;
  bool get isSubmitable => report.photo != null && report.photo.original != null;

  int get photoWidth {
    final div = _shadowRoot.querySelector('#photo');
    return div != null ? div.clientWidth : null;
  }
  int get photoHeight => photoWidth == null ? null : (photoWidth * 2 / 3).round();

  PaperActionDialog _dateDialog;
  PaperActionDialog get dateDialog {
    if (_dateDialog == null) _dateDialog = _shadowRoot.querySelector('#date-dialog');
    return _dateDialog;
  }
  PaperDialog _tideDialog;
  PaperDialog get tideDialog {
    if (_tideDialog == null) _tideDialog = _shadowRoot.querySelector('#tide-dialog');
    return _tideDialog;
  }
  PaperDialog _weatherDialog;
  PaperDialog get weatherDialog {
    if (_weatherDialog == null) _weatherDialog = _shadowRoot.querySelector('#weather-dialog');
    return _weatherDialog;
  }

  AddReportPage(Router router, RouteProvider routeProvider) : super(router) {
    try {
      report.asParam = routeProvider.parameters['report'];
      isReady = true;
    } catch (ex) {
      _logger.info("Adding new report.");
    }
  }

  void onShadowRoot(ShadowRoot sr) {
    _shadowRoot = sr;
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
      new GoogleMaps(_shadowRoot.querySelector('#google-maps'), report.location.geoinfo, mark: true);
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
          cond.weather = new Weather.fromMap(
              {'nominal': 'Clear', 'iconUrl': weatherIcon('Clear'), 'temperature': {'value': 20, 'unit': 'Cels'}});
        }
        report.condition = cond;
      }
    } catch (ex) {
      _logger.info("Failed to get conditions: ${ex}");
    }
  }

  submit() => rippling(() async {
    (await _onSession.future).submit(report);
  });

  showMap() => rippling(() {
    _logger.info("Show GoogleMaps");
  });

  dialogDate() {
    tmpDate = new DateTime(report.dateAt.year, report.dateAt.month, report.dateAt.day);
    tmpOclock = report.dateAt.hour;
    dateDialog.toggle();
  }
  commitCalendar() {
    report.dateAt = new DateTime(tmpDate.year, tmpDate.month, tmpDate.day, tmpOclock);
    _logger.fine("Commit date: ${report.dateAt}");
    renewConditions();
  }

  dialogTide() => tideDialog.toggle();
  changeTide(String name) {
    final tide = enumByName(tideList, name);
    if (tide != null) report.condition.tide = tide;
    tideDialog.toggle();
  }

  dialogWeather() => weatherDialog.toggle();
  changeWeather(String nominal) {
    report.condition.weather.nominal = nominal;
    report.condition.weather.iconUrl = weatherIcon(nominal);
    weatherDialog.toggle();
  }
}
