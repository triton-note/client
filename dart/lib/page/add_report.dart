library triton_note.page.reports_add;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_header_panel.dart';
import 'package:core_elements/core_animation.dart';
import 'package:core_elements/core_dropdown.dart';
import 'package:paper_elements/paper_toast.dart';

import 'package:triton_note/element/expandable_gmap.dart';
import 'package:triton_note/dialog/alert.dart';
import 'package:triton_note/dialog/edit_fish.dart';
import 'package:triton_note/dialog/edit_timestamp.dart';
import 'package:triton_note/dialog/edit_tide.dart';
import 'package:triton_note/dialog/edit_weather.dart';
import 'package:triton_note/dialog/geolocation.dart';
import 'package:triton_note/dialog/photo_way.dart';
import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/service/facebook.dart';
import 'package:triton_note/service/natural_conditions.dart';
import 'package:triton_note/service/photo_shop.dart';
import 'package:triton_note/service/preferences.dart';
import 'package:triton_note/service/reports.dart';
import 'package:triton_note/service/infer_spotname.dart';
import 'package:triton_note/service/geolocation.dart' as Geo;
import 'package:triton_note/service/googlemaps_browser.dart';
import 'package:triton_note/service/aws/s3file.dart';
import 'package:triton_note/util/blinker.dart';
import 'package:triton_note/util/cordova.dart';
import 'package:triton_note/util/enums.dart';
import 'package:triton_note/util/fabric.dart';
import 'package:triton_note/util/main_frame.dart';
import 'package:triton_note/util/getter_setter.dart';

final Logger _logger = new Logger('AddReportPage');

@Component(
    selector: 'add-report',
    templateUrl: 'packages/triton_note/page/add_report.html',
    cssUrl: 'packages/triton_note/page/add_report.css',
    useShadowDom: true)
class AddReportPage extends SubPage {
  Report report;

  final FuturedValue<PhotoWayDialog> photoWayDialog = new FuturedValue();
  final Getter<EditTimestampDialog> dateOclock = new PipeValue();
  final Getter<EditFishDialog> fishDialog = new PipeValue();
  final Getter<AlertDialog> alertDialog = new PipeValue();
  final Getter<GeolocationDialog> geolocationDialog = new PipeValue();

  Getter<Element> toolbar;
  _GMap gmap;
  _Conditions conditions;

  // Status
  final Completer<Null> _onUploaded = new Completer();
  final Completer<Null> _onGetConditions = new Completer();
  Future get _onSubmitable => Future.wait([_onUploaded.future, _onGetConditions.future]);

  bool isReady = false;
  bool get isLoading => report?.photo?.reduced?.mainview?.url == null;

  @override
  void onShadowRoot(ShadowRoot sr) {
    super.onShadowRoot(sr);

    toolbar = new CachedValue(() => root.querySelector('core-header-panel[main] core-toolbar'));

    photoWayDialog.future.then((dialog) {
      dialog.onClossing(() {
        final take = dialog.take;
        if (take != null) _choosePhoto(take);
        else back();
      });
      dialog.open();
    });

    gmap = new _GMap(
        root,
        new GetterSetter(() => report.location.name, (v) => report.location.name = v),
        new GetterSetter(() => report.location.geoinfo, (pos) {
          report.location.geoinfo = pos;
          renewLocation();
        }));
    conditions = new _Conditions(root, new Getter(() => report.condition));
  }

  DateTime get dateAt => report?.dateAt;
  set dateAt(DateTime v) {
    report?.dateAt = v;
    renewDate();
  }

  Future<GeoInfo> _getGeoInfo() async {
    final result = new Completer();
    final dialog = geolocationDialog.value;
    loop() async {
      try {
        result.complete(await Geo.getHere());
      } catch (ex) {
        if (isAndroid && !(await Geo.isEnabled)) {
          dialog.open();
        } else {
          result.complete(Geo.defaultLocation);
        }
      }
    }
    dialog.onClosed(loop);
    loop();
    return result.future;
  }

  /**
   * Choosing photo and get conditions and inference.
   */
  _choosePhoto(bool take) async {
    try {
      _onSubmitable.then((_) => _submitable());

      final shop = new PhotoShop(take);

      report = new Report.fromMap({
        'location': {},
        'condition': {'weather': {}}
      });
      report.photo.reduced.mainview.url = await shop.photoUrl;

      _upload(await shop.photo);

      isReady = true;

      try {
        report.dateAt = await shop.timestamp;
      } catch (ex) {
        _logger.info("No Timestamp in Exif: ${ex}");
      }

      try {
        report.location.geoinfo = await shop.geoinfo;
      } catch (ex) {
        _logger.info("No GeoInfo in Exif: ${ex}");
        report.location.geoinfo = await _getGeoInfo();
      }
      renewLocation();

      try {
        final fishes = null;
        if (fishes != null && fishes.length > 0) {
          report.fishes.addAll(fishes);
        }
      } catch (ex) {
        _logger.info("Failed to infer fishes: ${ex}");
      }
    } catch (ex) {
      _logger.warning(() => "Failed to choose photo: ${ex}");
      back();
    }
  }

  _upload(Blob photo) async {
    final path = await report.photo.original.storagePath;
    await S3File.putObject(path, photo);
    _onUploaded.complete();
    FabricAnswers.eventCustom(name: 'UploadPhoto', attributes: {'type': 'NEW_REPORT'});
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
        if (!_onGetConditions.isCompleted) _onGetConditions.complete();
      }
    } catch (ex) {
      _logger.info("Failed to get conditions: ${ex}");
    }
  }

  renewLocation() async {
    renewConditions();
    try {
      final spotName = await InferSpotName.infer(report.location.geoinfo);
      if (spotName != null && spotName.length > 0) {
        report.location.name = spotName;
      }
    } catch (ex) {
      _logger.info("Failed to infer spot name: ${ex}");
    }
  }

  renewDate() async {
    renewConditions();
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

  _fishNameBlinkArea() => [root.querySelector('#catches .control .fish-name input')];
  static const fishNameBlinkDuration = const Duration(milliseconds: 350);
  static const fishNameBlinkUpDuration = const Duration(milliseconds: 100);
  static const fishNameBlinkDownDuration = const Duration(milliseconds: 100);
  static const fishNameBlinkFrames = const [
    const {'background': "transparent"},
    const {'background': "#fee"}
  ];

  addFish() {
    if (addingFishName != null && addingFishName.isNotEmpty) {
      final fish = new Fishes.fromMap({'name': addingFishName, 'count': 1});
      addingFishName = null;
      report.fishes.add(fish);
    } else {
      final blinker = new Blinker(fishNameBlinkUpDuration, fishNameBlinkDownDuration,
          [new BlinkTarget(new Getter(_fishNameBlinkArea), fishNameBlinkFrames)]);
      blinker.start();
      new Future.delayed(fishNameBlinkDuration, () {
        blinker.stop();
      });
    }
  }

  editFish(int index) {
    if (0 <= index && index < report.fishes.length) {
      fishDialog.value.openWith(new GetterSetter(() => report.fishes[index], (v) {
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

  back() {
    if (!isSubmitting) {
      if (report != null) {
        FabricAnswers.eventCustom(name: 'CancelReport');
        delete(path) async {
          try {
            await S3File.delete(path);
          } catch (ex) {
            _logger.warning(() => "Failed to delete on S3(${path}): ${ex}");
          }
        }
        report.photo.original.storagePath.then(delete);
        new Future.delayed(new Duration(minutes: 1), () {
          report.photo.reduced..mainview.storagePath.then(delete)..thumbnail.storagePath.then(delete);
        });
      }
      super.back();
    }
  }

  bool isSubmitting = false;
  DivElement get divSubmit => root.querySelector('core-toolbar div#submit');
  CoreDropdown get dropdownSubmit => divSubmit.querySelector('core-dropdown');

  toast(String msg, [Duration dur = const Duration(seconds: 8)]) =>
      root.querySelector('#submit paper-toast') as PaperToast
        ..classes.remove('fit-bottom')
        ..duration = dur.inMilliseconds
        ..text = msg
        ..show();

  void _submitable() {
    _logger.fine("Appearing submit button");
    final x = document.body.clientWidth;
    final y = (x / 5).round();
    new CoreAnimation()
      ..target = (divSubmit.querySelector('.action')..style.display = 'block')
      ..duration = 300
      ..fill = "both"
      ..keyframes = [
        {'transform': "translate(-${x}px, ${y}px)", 'opacity': '0'},
        {'transform': "none", 'opacity': '1'}
      ]
      ..play();
  }

  submit(bool publish) => rippling(() async {
        _logger.finest("Submitting report: ${report}");
        dropdownSubmit.close();
        if (report.location.name == null || report.location.name.isEmpty) report.location.name = "My Spot";
        isSubmitting = true;

        doit(String name, Future proc()) async {
          try {
            await proc();
            return true;
          } catch (ex) {
            _logger.warning(() => "Failed to ${name}: ${ex}");
            alertDialog.value
              ..message = "Failed to ${name} your report. Please try again later."
              ..open();
            return false;
          }
        }

        bool ok = false;
        try {
          ok = await doit('add', () => Reports.add(report));
          if (ok) {
            FabricAnswers.eventCustom(name: 'AddReport');
          }
          if (ok && publish) {
            final published = await doit('publish', () => FBPublish.publish(report));
            if (published) try {
              toast("Completed on publishing to Facebook");
              await Reports.update(report);
            } catch (ex) {
              _logger.warning(() => "Failed to update published id: ${ex}");
            }
          }
        } catch (ex) {
          _logger.warning(() => "Error on submitting: ${ex}");
        } finally {
          isSubmitting = false;
          if (ok) back();
        }
      });
}

class _GMap {
  final ShadowRoot _root;
  final GetterSetter<String> spotName;
  final GetterSetter<GeoInfo> _geoinfo;
  GeoInfo get geoinfo => _geoinfo.value;
  Getter<Element> getScroller;
  Getter<Element> getBase;
  final FuturedValue<ExpandableGMapElement> gmapElement = new FuturedValue();
  final FuturedValue<GoogleMap> setGMap = new FuturedValue();

  _GMap(this._root, this.spotName, this._geoinfo) {
    getBase = new Getter<Element>(() => _root.querySelector('#input'));
    getScroller = new Getter<Element>(() {
      final panel = _root.querySelector('core-header-panel[main]') as CoreHeaderPanel;
      return (panel == null) ? null : panel.scroller;
    });

    gmapElement.future.then((elem) {
      elem
        ..onExpanding = (gmap) {
          gmap
            ..showMyLocationButton = true
            ..options.draggable = true
            ..options.disableDoubleClickZoom = false;
        }
        ..onShrinking = (gmap) {
          gmap
            ..showMyLocationButton = false
            ..options.draggable = false
            ..options.disableDoubleClickZoom = true;
        };
    });

    setGMap.future.then((gmap) {
      gmap
        ..putMarker(_geoinfo.value)
        ..options.draggable = false
        ..onClick = (pos) {
          _logger.fine("Point map: ${pos}");
          _geoinfo.value = pos;
          gmap.clearMarkers();
          gmap.putMarker(pos);
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
