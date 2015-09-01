library triton_note.page.reports_add;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_header_panel.dart';
import 'package:core_elements/core_animation.dart';

import 'package:triton_note/dialog/edit_fish.dart';
import 'package:triton_note/dialog/edit_timestamp.dart';
import 'package:triton_note/dialog/edit_tide.dart';
import 'package:triton_note/dialog/edit_weather.dart';
import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/service/natural_conditions.dart';
import 'package:triton_note/service/photo_shop.dart';
import 'package:triton_note/service/preferences.dart';
import 'package:triton_note/service/reports.dart';
import 'package:triton_note/service/geolocation.dart' as Geo;
import 'package:triton_note/service/googlemaps_browser.dart';
import 'package:triton_note/service/aws/s3file.dart';
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
  Report report;

  final PipeValue<EditTimestampDialog> dateOclock = new PipeValue();
  final PipeValue<EditFishDialog> fishDialog = new PipeValue();

  _GMap gmap;
  _Conditions conditions;

  bool get isReady => report != null;
  bool get isLoading => report.photo == null;

  AddReportPage(Router router) : super(router);

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

    report = new Report.fromMap({'location': {}, 'condition': {'weather': {}}});

    shop.photoUrl.then((url) {
      report.photo.reduced.mainview.url = url;
      _logger.finest(() => "Selected photo's local reference: ${report.photo},  (isLoading=${isLoading})");
    });

    shop.photo.then((photo) async {
      _upload(photo);

      try {
        report.dateAt = await shop.timestamp;
      } catch (ex) {
        _logger.info("No Timestamp in Exif: ${ex}");
      }

      try {
        report.location.geoinfo = await shop.geoinfo;
      } catch (ex) {
        _logger.info("No GeoInfo in Exif: ${ex}");
        report.location.geoinfo = await Geo.location();
      }
      renewConditions();

      try {
        final inference = null;
        if (inference != null) {
          if (inference.spotName != null && inference.spotName.length > 0) {
            report.location.name = inference.spotName;
          }
          if (inference.fishes != null && inference.fishes.length > 0) {
            report.fishes.addAll(inference.fishes);
          }
        }
      } catch (ex) {
        _logger.info("Failed to infer: ${ex}");
      }
    });
  });

  _upload(Blob photo) async {
    try {
      final path = await report.photo.original.storagePath;
      await S3File.putObject(path, photo);
      submitable();
    } catch (ex) {
      _logger.warning("Failed to upload: ${ex}");
    }
  }

  /**
   * Refresh conditions, on changing location or timestamp.
   */
  renewConditions() async {
    try {
      _logger.finest("Getting conditions by report info: ${report}");
      if (report.dateAt != null && report.location.geoinfo != null) {
        final cond = await NaturalConditions.at(report.dateAt, report.location.geoinfo);
        _logger.fine("Get conditions: ${cond}");
        if (cond.weather == null) {
          cond.weather =
              new Weather.fromMap({'nominal': 'Clear', 'iconUrl': Weather.nominalMap['Clear'], 'temperature': 20});
        }
        if (cond.weather.temperature != null) {
          cond.weather.temperature =
              cond.weather.temperature.convertTo((await UserPreferences.current).measures.temperature);
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
      report.fishes.add(fish);
    }
  }

  editFish(int index) {
    if (0 <= index && index < report.fishes.length) {
      fishDialog.value.open(new GetterSetter(() => report.fishes[index], (v) {
        if (v == null) {
          report.fishes..removeAt(index);
        } else {
          report.fishes..[index] = v;
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
    final x = document.body.clientWidth;
    final y = (x / 5).round();
    new CoreAnimation()
      ..target = div
      ..duration = 300
      ..fill = "both"
      ..keyframes = [{'transform': "translate(-${x}px, ${y}px)", 'opacity': '0'}, {'transform': "none", 'opacity': '1'}]
      ..play();
  }

  submit() => rippling(() async {
    _logger.finest("Submitting report: ${report}");
    if (report.location.name == null || report.location.name.isEmpty) report.location.name = "My Spot";
    Reports.add(report);
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
  final ShadowRoot _root;
  final Getter<Condition> _condition;
  final Getter<EditWeatherDialog> weatherDialog = new PipeValue();
  final Getter<EditTideDialog> tideDialog = new PipeValue();

  _Conditions(this._root, this._condition);

  Condition get value => _condition.value;

  dialogTide() => tideDialog.value.open();
  dialogWeather() => weatherDialog.value.open();

  String get weatherName => value.weather == null ? null : value.weather.nominal;
  String get weatherImage => value.weather == null ? null : value.weather.iconUrl;
  String get tideName => value.tide == null ? null : nameOfEnum(value.tide);
  String get tideImage => tideName == null ? null : Tides.iconBy(tideName);
  String get moonImage => _condition.value.moon == null ? null : MoonPhases.iconOf(_condition.value.moon);
}
