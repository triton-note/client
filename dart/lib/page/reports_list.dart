library triton_note.page.reports_list;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_animation.dart';
import 'package:core_elements/core_animated_pages.dart';
import 'package:core_elements/core_header_panel.dart';
import 'package:core_elements/core_dropdown.dart';
import 'package:paper_elements/paper_icon_button.dart';
import 'package:paper_elements/paper_autogrow_textarea.dart';
import 'package:paper_elements/paper_toast.dart';

import 'package:triton_note/dialog/confirm.dart';
import 'package:triton_note/dialog/edit_fish.dart';
import 'package:triton_note/dialog/edit_timestamp.dart';
import 'package:triton_note/dialog/edit_tide.dart';
import 'package:triton_note/dialog/edit_weather.dart';
import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/location.dart' as Loc;
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/preferences.dart';
import 'package:triton_note/service/reports.dart';
import 'package:triton_note/service/facebook.dart';
import 'package:triton_note/service/natural_conditions.dart';
import 'package:triton_note/service/googlemaps_browser.dart';
import 'package:triton_note/util/blinker.dart';
import 'package:triton_note/util/enums.dart';
import 'package:triton_note/util/cordova.dart';
import 'package:triton_note/util/pager.dart';
import 'package:triton_note/util/geometry.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('ReportsListPage');

@Component(
    selector: 'reports-list',
    templateUrl: 'packages/triton_note/page/reports_list.html',
    cssUrl: 'packages/triton_note/page/reports_list.css',
    useShadowDom: true)
class ReportsListPage extends MainPage {
  final pageSize = 20;

  PagingList<Report> reports;
  bool noReports = false;
  int _indexOfReport;
  Report report;

  Getter<CoreAnimatedPages> _pages;
  int get selectedPage => _pages?.value?.selected;

  ReportsListPage(Router router) : super(router);

  void onShadowRoot(ShadowRoot sr) {
    super.onShadowRoot(sr);
    _pages = new CachedValue(() => root.querySelector('core-animated-pages'));

    photo = new _PhotoSize(root, new Getter(() => _fitSizes[_indexOfReport]?.value));
    comment = new _Comment(root, _onChanged, new Getter(() => report));
    catches = new _Catches(root, _onChanged, new Getter(() => report?.fishes));
    conditions = new _Conditions(_onChanged, new Getter(() => report?.condition));
    location = new _Location(root, _onChanged, new Getter(() => report?.location));
    moreMenu = new _MoreMenu(root, _onChanged, new Getter(() => report), backToList);

    _parts = [photo, comment, catches, conditions, location, moreMenu];

    Reports.paging.then((paging) async {
      hideSplashScreen();

      await paging.more(pageSize);
      reports = paging;
      noReports = reports.list.isEmpty && !reports.hasMore;

      new Future.delayed(new Duration(seconds: 1), () {
        if (noReports) {
          final target = root.querySelector('section#list .list .no-reports');
          final dy = (window.innerHeight / 4).round();

          _logger.finest(() => "Show add_first_report button: ${target}: +${dy}");
          new CoreAnimation()
            ..target = target
            ..duration = 180
            ..easing = 'ease-in'
            ..fill = "both"
            ..keyframes = [
              {'transform': "none", 'opacity': '0'},
              {'transform': "translate(0px, ${dy}px)", 'opacity': '1'}
            ]
            ..play();
        }
      });
    });
  }

  addReport() {
    router.go('add', {});
  }

  goReport(int index) {
    _indexOfReport = index;
    report = reports.list[_indexOfReport].clone();
    _pages.value.selected = 1;
  }

  backToList() {
    _pages.value.selected = 0;

    _parts.forEach((p) => p.detach());

    if (_submitTimer != null && _submitTimer.isActive) {
      _submitTimer.cancel();
      _update();
    }
  }

  final Map<int, PipeValue<Size>> _fitSizes = {};
  Setter<Size> fitSetter(int index) => _fitSizes[index] ??= new PipeValue();

  _Comment comment;
  _Catches catches;
  _PhotoSize photo;
  _Location location;
  _Conditions conditions;
  _MoreMenu moreMenu;
  List<_PartOfPage> _parts;

  Getter<EditTimestampDialog> editTimestamp = new PipeValue();
  Timer _submitTimer;

  void detach() {
    super.detach();
  }

  DateTime get timestamp => report == null ? null : report.dateAt;
  set timestamp(DateTime v) {
    if (report != null && v != null && v != report.dateAt) {
      report.dateAt = v;
      conditions._update(v);
      _onChanged(v);
    }
  }

  void _onChanged(newValue) {
    _logger.finest("Changed value(${newValue}), Start timer to submit.");
    if (_submitTimer != null && _submitTimer.isActive) _submitTimer.cancel();
    _submitTimer = new Timer(submitDuration, _update);
  }

  void _update() {
    Reports.update(report);
  }
}

const String editFlip = "create";
const String editFlop = "done";

const Duration blinkDuration = const Duration(seconds: 2);
const Duration blinkDownDuration = const Duration(milliseconds: 300);
const frameBackground = const [
  const {'background': "#fffcfc"},
  const {'background': "#fee"}
];
const frameBackgroundDown = const [
  const {'background': "#fee"},
  const {'background': "white"}
];

const submitDuration = const Duration(minutes: 1);

typedef void OnChanged(newValue);

abstract class _PartOfPage {
  void detach();
}

class _MoreMenu extends _PartOfPage {
  final ShadowRoot _root;
  final Getter<Report> _report;
  final OnChanged _onChanged;
  final _back;

  Getter<ConfirmDialog> confirmDialog = new PipeValue();
  final PipeValue<bool> dialogResult = new PipeValue();

  _MoreMenu(this._root, this._onChanged, this._report, void back()) : this._back = back;

  bool get publishable => _report.value?.published?.facebook == null;
  CoreDropdown get dropdown => _root.querySelector('#more-menu core-dropdown');

  void detach() {}

  confirm(String message, whenOk()) {
    dropdown.close();
    confirmDialog.value
      ..message = message
      ..onClossing(() {
        if (confirmDialog.value.result) whenOk();
      })
      ..open();
  }

  toast(String msg) => _root.querySelector('#more-menu paper-toast') as PaperToast
    ..classes.remove('fit-bottom')
    ..text = msg
    ..show();

  publish() => confirm("Publish to Facebook ?", () async {
        try {
          final published = await FBPublish.publish(_report.value);
          _onChanged(published);
          toast("Completed on publishing to Facebook");
        } catch (ex) {
          _logger.warning(() => "Error on publishing to Facebook: ${ex}");
          toast("Failed on publishing to Facebook");
        }
      });

  delete() => confirm("Delete this report ?", () async {
        await Reports.remove(_report.value.id);
        _back();
      });
}

class _Comment extends _PartOfPage {
  final ShadowRoot _root;
  final OnChanged _onChanged;
  final Getter<Report> _report;

  CachedValue<List<Element>> _area;
  PaperIconButton _editButton;
  Blinker _blinker;

  bool isEditing = false;

  _Comment(this._root, this._onChanged, this._report) {
    _area = new CachedValue(() => _root.querySelectorAll('#comment .editor').toList(growable: false));
    _blinker = new Blinker(blinkDuration, blinkDownDuration, [new BlinkTarget(_area, frameBackground)]);
  }

  bool get isEmpty => _report.value?.comment?.isEmpty ?? true;

  String get text => _report.value?.comment;
  set text(String v) {
    if (v == null || _report.value.comment == v) return;
    _report.value.comment = v;
    _onChanged(v);
  }

  void detach() {
    _editStop();
  }

  toggle(event) {
    _editButton = event.target as PaperIconButton;
    _logger.fine("Toggle edit: ${_editButton.icon}");

    if (isEditing) {
      _editStop();
    } else {
      _editStart();
    }
  }

  _editStart() {
    if (_editButton == null || isEditing) return;

    _editButton.icon = editFlop;
    _logger.finest("Start editing comment.");
    isEditing = true;
    new Future.delayed(new Duration(milliseconds: 10), () {
      final a = _root.querySelector('#comment .editor  paper-autogrow-textarea') as PaperAutogrowTextarea;
      a.update(a.querySelector('textarea'));

      _area.clear();
      _blinker.start();
    });
  }

  _editStop() {
    if (_editButton == null || !isEditing) return;

    _editButton.icon = editFlip;
    _blinker.stop();
    new Future.delayed(_blinker.blinkStopDuration, () {
      isEditing = false;
    });
  }
}

class _Catches extends _PartOfPage {
  static const frameButton = const [
    const {'opacity': 0.05},
    const {'opacity': 1}
  ];

  final ShadowRoot _root;
  final OnChanged _onChanged;
  final Getter<List<Fishes>> _list;
  final GetterSetter<EditFishDialog> dialog = new PipeValue();

  CachedValue<List<Element>> _addButton;
  CachedValue<List<Element>> _fishItems;
  PaperIconButton _editButton;
  Blinker _blinker;

  bool isEditing = false;

  _Catches(this._root, this._onChanged, this._list) {
    _addButton = new CachedValue(() => _root.querySelectorAll('#fishes paper-icon-button.add').toList(growable: false));
    _fishItems = new CachedValue(() => _root.querySelectorAll('#fishes .content').toList(growable: false));

    _blinker = new Blinker(blinkDuration, blinkDownDuration,
        [new BlinkTarget(_addButton, frameButton), new BlinkTarget(_fishItems, frameBackground, frameBackgroundDown)]);
  }

  void detach() {
    _editStop();
  }

  toggle(event) {
    _editButton = event.target as PaperIconButton;
    _logger.fine("Toggle edit: ${_editButton.icon}");

    if (isEditing) {
      _editStop();
    } else {
      _editStart();
    }
  }

  _editStart() {
    if (_editButton == null || isEditing) return;

    _editButton.icon = editFlop;
    isEditing = true;
    new Future.delayed(new Duration(milliseconds: 10), () {
      _addButton.clear();
      _fishItems.clear();
      _blinker.start();
    });
  }

  _editStop() {
    if (_editButton == null || !isEditing) return;

    _editButton.icon = editFlip;
    _blinker.stop();
    new Future.delayed(_blinker.blinkStopDuration, () {
      isEditing = false;
    });
  }

  add() => alfterRippling(() {
        _logger.fine("Add new fish");
        final fish = new Fishes.fromMap({'count': 1});
        dialog.value.openWith(new GetterSetter(() => fish, (v) {
          _list.value.add(v);
          _onChanged(_list.value);
        }));
      });

  edit(index) => alfterRippling(() {
        _logger.fine("Edit at $index");
        dialog.value.openWith(new GetterSetter(() => _list.value[index], (v) {
          if (v == null) {
            _list.value.removeAt(index);
          } else {
            _list.value[index] = v;
          }
          _onChanged(_list.value);
        }));
      });
}

class _Location extends _PartOfPage {
  static const frameBorder = const [
    const {'border': "solid 2px #fee"},
    const {'border': "solid 2px #f88"}
  ];
  static const frameBorderStop = const [
    const {'border': "solid 2px #f88"},
    const {'border': "solid 2px white"}
  ];

  final ShadowRoot _root;
  final Getter<Loc.Location> _location;
  final OnChanged _onChanged;
  Getter<Element> getScroller;
  Getter<Element> getBase;
  Setter<GoogleMap> setGMap;
  GoogleMap _gmap;

  CachedValue<List<Element>> _blinkInput, _blinkBorder;
  PaperIconButton _editButton;
  Blinker _blinker;

  bool isEditing;

  String get spotName => _location.value?.name;
  set spotName(String v) {
    if (v == null || _location.value?.name == v) return;
    _location.value?.name = v;
    _onChanged(v);
  }

  Loc.GeoInfo get geoinfo => _location.value?.geoinfo;
  set geoinfo(Loc.GeoInfo v) {
    if (v == null || _location.value?.geoinfo == v) ;
    _location.value?.geoinfo = v;
    _onChanged(v);
  }

  _Location(this._root, this._onChanged, this._location) {
    getBase = new Getter<Element>(() => _root.querySelector('#base'));
    getScroller = new Getter<Element>(() {
      final panel = _root.querySelector('core-header-panel[main]') as CoreHeaderPanel;
      return (panel == null) ? null : panel.scroller;
    });
    setGMap = new Setter<GoogleMap>((v) {
      _gmap = v
        ..options.draggable = false
        ..putMarker(_location.value?.geoinfo);
      _root.querySelector('#location expandable-gmap')
        ..on['expanding'].listen((event) {
          _gmap.showMyLocationButton = true;
          _gmap.options.draggable = true;
          _gmap.options.disableDoubleClickZoom = false;
        })
        ..on['shrinking'].listen((event) {
          _gmap.showMyLocationButton = false;
          _gmap.options.draggable = false;
          _gmap.options.disableDoubleClickZoom = true;
        });
    });

    _blinkInput = new CachedValue(() => _root.querySelectorAll('#location .editor input').toList(growable: false));
    _blinkBorder = new CachedValue(() => _root.querySelectorAll('#location .content .gmap').toList(growable: false));

    _blinker = new Blinker(blinkDuration, blinkDownDuration,
        [new BlinkTarget(_blinkInput, frameBackground), new BlinkTarget(_blinkBorder, frameBorder, frameBorderStop)]);
  }

  void detach() {
    _editStop();
  }

  toggle(event) {
    _editButton = event.target as PaperIconButton;
    _logger.fine("Toggle edit: ${_editButton.icon}");

    if (isEditing) {
      _editStop();
    } else {
      _editStart();
    }
  }

  _editStart() {
    if (_editButton == null || isEditing) return;

    _editButton.icon = editFlop;
    _logger.finest("Start editing location.");
    isEditing = true;
    new Future.delayed(new Duration(milliseconds: 10), () {
      _blinkInput.clear();
      _blinkBorder.clear();
      _blinker.start();
    });
    _gmap.onClick = (pos) {
      _gmap.clearMarkers();
      _gmap.putMarker(pos);
      geoinfo = pos;
    };
  }

  _editStop() {
    if (_editButton == null || !isEditing) return;

    _editButton.icon = editFlip;
    _blinker.stop();
    new Future.delayed(_blinker.blinkStopDuration, () {
      isEditing = false;
    });
    _gmap.onClick = null;
  }
}

class _PhotoSize extends _PartOfPage {
  final ShadowRoot _root;
  final Getter<Size> _fitSize;
  ImageElement img;

  _PhotoSize(this._root, this._fitSize);

  void detach() {
    img.style.opacity = '0';
  }

  Size get _maxSize {
    if (_fitSize.value == null) return null;

    final max = _root.querySelector('#mainFrame').clientWidth.toDouble();
    final w = _fitSize.value.width;
    final h = _fitSize.value.height;
    if (w > h) {
      return new Size(max, max * h / w);
    } else {
      return new Size(max * w / h, max);
    }
  }

  int get width => _maxSize?.width?.round();
  int get height => _maxSize?.height?.round();

  loaded(event) {
    _logger.fine("Image loaded: ${event.target}");
    img = event.target;
    img.style.opacity = '1';
  }
}

class _Conditions extends _PartOfPage {
  final Getter<Loc.Condition> _src;
  final OnChanged _onChanged;
  final _WeatherWrapper weather;
  final Getter<EditWeatherDialog> weatherDialog = new PipeValue();
  final Getter<EditTideDialog> tideDialog = new PipeValue();

  _Conditions(OnChanged onChanged, Getter<Loc.Condition> src)
      : this._src = src,
        this._onChanged = onChanged,
        this.weather = new _WeatherWrapper(new Getter(() => src.value?.weather), onChanged);

  void detach() {}

  Loc.Tide get tide => _src.value?.tide;
  set tide(Loc.Tide v) {
    if (_src.value?.tide == v) return;
    _src.value?.tide = v;
    _onChanged(v);
  }

  String get tideName => nameOfEnum(_src.value?.tide);
  String get tideImage => Loc.Tides.iconOf(_src.value?.tide);

  int get moon => _src.value?.moon;
  String get moonImage => Loc.MoonPhases.iconOf(_src.value?.moon);

  dialogWeather() => weatherDialog.value.open();
  dialogTide() => tideDialog.value.open();

  _update(DateTime now) async {
    final moon = await Moon.at(now);
    _src.value?.moon = moon.age.round();
  }
}

class _WeatherWrapper implements Loc.Weather {
  final Getter<Loc.Weather> _src;
  final OnChanged _onChanged;

  _WeatherWrapper(this._src, this._onChanged);

  Map get asMap => _src.value?.asMap;

  Future<TemperatureUnit> _temperatureUnit;
  Temperature _temperature;
  Temperature get temperature {
    if (_temperature == null && _temperatureUnit == null && _src.value != null) {
      _temperatureUnit = UserPreferences.current.then((c) => c.measures.temperature);
      _temperatureUnit.then((unit) {
        _temperature = _src.value.temperature.convertTo(unit);
        _temperatureUnit = null;
      });
    }
    return _temperature;
  }

  set temperature(Temperature v) {
    if (v == null) return;
    if (_temperature != null && _temperature == v) return;
    _src.value?.temperature = v;
    _temperature = null;
    _onChanged(v);
  }

  String get nominal => _src.value?.nominal;
  set nominal(String v) {
    if (v == null || _src.value?.nominal == v) return;
    _src.value?.nominal = v;
    _onChanged(v);
  }

  String get iconUrl => _src.value?.iconUrl;
  set iconUrl(String v) {
    if (v == null || _src.value?.iconUrl == v) return;
    _src.value?.iconUrl = v;
    _onChanged(v);
  }
}
