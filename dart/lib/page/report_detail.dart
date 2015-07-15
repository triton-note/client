library triton_note.page.report_detail;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_animation.dart';
import 'package:core_elements/core_animated_pages.dart';
import 'package:core_elements/core_header_panel.dart';
import 'package:paper_elements/paper_icon_button.dart';
import 'package:paper_elements/paper_autogrow_textarea.dart';

import 'package:triton_note/dialog/edit_fish.dart';
import 'package:triton_note/dialog/edit_timestamp.dart';
import 'package:triton_note/dialog/edit_tide.dart';
import 'package:triton_note/dialog/edit_weather.dart';
import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/location.dart' as Loc;
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/preferences.dart';
import 'package:triton_note/service/reports.dart';
import 'package:triton_note/service/server.dart';
import 'package:triton_note/service/googlemaps_browser.dart';
import 'package:triton_note/util/blinker.dart';
import 'package:triton_note/util/enums.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('ReportDetailPage');

const String editFlip = "create";
const String editFlop = "done";

const Duration blinkDuration = const Duration(seconds: 2);
const Duration blinkDownDuration = const Duration(milliseconds: 300);
const frameBackground = const [const {'background': "#fffcfc"}, const {'background': "#fee"}];
const frameBackgroundDown = const [const {'background': "#fee"}, const {'background': "white"}];

const submitDuration = const Duration(minutes: 1);

typedef void OnChanged();

@Component(
    selector: 'report-detail',
    templateUrl: 'packages/triton_note/page/report_detail.html',
    cssUrl: 'packages/triton_note/page/report_detail.css',
    useShadowDom: true)
class ReportDetailPage extends MainFrame {
  Future<Report> _report;
  Report report;
  _Comment comment;
  _Catches catches;
  _PhotoSize photo;
  _Location location;
  _Conditions conditions;
  GetterSetter<EditTimestampDialog> editTimestamp = new PipeValue();
  Timer submitTimer;

  ReportDetailPage(Router router, RouteProvider routeProvider) : super(router) {
    final String reportId = routeProvider.parameters['reportId'];
    _report = Reports.get(reportId);
  }

  @override
  void onShadowRoot(ShadowRoot sr) {
    super.onShadowRoot(sr);

    photo = new _PhotoSize(root);

    _report.then((v) async {
      report = v;
      comment = new _Comment(root, _onChanged, report);
      catches = new _Catches(root, _onChanged, new GetterSetter(() => report.fishes, (v) => report.fishes = v));
      conditions = new _Conditions(report.condition, _onChanged);
      location = new _Location(root, report.location, _onChanged);
    });
  }

  DateTime get timestamp => report == null ? null : report.dateAt;
  set timestamp(DateTime v) {
    if (report != null) {
      report.dateAt = v;
      _onChanged();
    }
  }

  void _onChanged() {
    if (submitTimer != null && submitTimer.isActive) submitTimer.cancel();
    submitTimer = new Timer(submitDuration, _update);
    _logger.finest("Timer to submit start.");
  }

  void _update() {
    Server.update(report);
  }
}

class _Comment {
  final ShadowRoot _root;
  final OnChanged _onChanged;
  final Report _report;

  CachedValue<List<Element>> _area;
  Blinker _blinker;

  bool isEditing = false;

  _Comment(this._root, this._onChanged, this._report) {
    _area = new CachedValue(() => _root.querySelectorAll('#comment .editor').toList(growable: false));
    _blinker = new Blinker(blinkDuration, blinkDownDuration, [new BlinkTarget(_area, frameBackground)]);
  }

  bool get isEmpty => _report.comment == null || _report.comment.isEmpty;

  String get text => _report.comment;
  set text(String v) {
    _report.comment = v;
    _onChanged();
  }

  toggle(event) {
    final button = event.target as PaperIconButton;
    _logger.fine("Toggle edit: ${button.icon}");
    button.icon = isEditing ? editFlip : editFlop;

    if (isEditing) {
      _blinker.stop();
      new Future.delayed(_blinker.blinkStopDuration, () {
        isEditing = false;
      });
    } else {
      _logger.finest("Start editing comment.");
      isEditing = true;
      new Future.delayed(new Duration(milliseconds: 10), () {
        final a = _root.querySelector('#comment .editor  paper-autogrow-textarea') as PaperAutogrowTextarea;
        a.update(a.querySelector('textarea'));

        _area.clear();
        _blinker.start();
      });
    }
  }
}

class _Catches {
  static const frameButton = const [const {'opacity': 0.05}, const {'opacity': 1}];

  final ShadowRoot _root;
  final OnChanged _onChanged;
  final GetterSetter<List<Fishes>> list;
  final GetterSetter<EditFishDialog> dialog = new PipeValue();

  CachedValue<List<Element>> _addButton;
  CachedValue<List<Element>> _fishItems;
  Blinker _blinker;

  bool isEditing = false;

  _Catches(this._root, this._onChanged, this.list) {
    _addButton = new CachedValue(() => _root.querySelectorAll('#fishes paper-icon-button.add').toList(growable: false));
    _fishItems = new CachedValue(() => _root.querySelectorAll('#fishes div.item').toList(growable: false));

    _blinker = new Blinker(blinkDuration, blinkDownDuration, [
      new BlinkTarget(_addButton, frameButton),
      new BlinkTarget(_fishItems, frameBackground, frameBackgroundDown)
    ]);
  }

  toggle(event) {
    final button = event.target as PaperIconButton;
    _logger.fine("Toggle edit: ${button.icon}");
    button.icon = isEditing ? editFlip : editFlop;

    if (isEditing) {
      _blinker.stop();
      new Future.delayed(_blinker.blinkStopDuration, () {
        isEditing = false;
      });
    } else {
      isEditing = true;
      new Future.delayed(new Duration(milliseconds: 10), () {
        _addButton.clear();
        _fishItems.clear();
        _blinker.start();

        _fishItems.value.forEach((item) {
          item.querySelector('paper-ripple').style
            ..position = "absolute"
            ..top = '0'
            ..bottom = '0'
            ..left = '0'
            ..right = '0';
        });
      });
    }
  }

  add() => alfterRippling(() {
    _logger.fine("Add new fish");
    final fish = new Fishes.fromMap({'count': 1});
    dialog.value.open(new GetterSetter(() => fish, (v) {
      list.value = list.value..add(v);
      _onChanged();
    }));
  });

  edit(index) => alfterRippling(() {
    _logger.fine("Edit at $index");
    dialog.value.open(new GetterSetter(() => list.value[index], (v) {
      if (v == null) {
        list.value = list.value..removeAt(index);
      } else {
        list.value = list.value..[index] = v;
      }
      _onChanged();
    }));
  });
}

class _Location {
  static const frameBorder = const [const {'border': "solid 2px #fee"}, const {'border': "solid 2px #f88"}];
  static const frameBorderStop = const [const {'border': "solid 2px #f88"}, const {'border': "solid 2px white"}];

  final ShadowRoot _root;
  final Loc.Location _location;
  final OnChanged _onChanged;
  Getter<Element> getScroller;
  Getter<Element> getBase;
  Setter<GoogleMap> setGMap;
  GoogleMap _gmap;

  CachedValue<List<Element>> _blinkInput, _blinkBorder;
  Blinker _blinker;

  bool isEditing;

  String get spotName => _location.name;
  set spotName(String v) {
    _location.name = v;
    _onChanged();
  }
  Loc.GeoInfo get geoinfo => _location.geoinfo;
  set geoinfo(Loc.GeoInfo v) {
    _location.geoinfo = v;
    _onChanged();
  }

  _Location(this._root, this._location, this._onChanged) {
    getBase = new Getter<Element>(() => _root.querySelector('#base'));
    getScroller = new Getter<Element>(() {
      final panel = _root.querySelector('core-header-panel[main]') as CoreHeaderPanel;
      return (panel == null) ? null : panel.scroller;
    });
    setGMap = new Setter<GoogleMap>((v) {
      _gmap = v;
      _gmap.putMarker(_location.geoinfo);
    });

    _blinkInput = new CachedValue(() => _root.querySelectorAll('#location .editor input').toList(growable: false));
    _blinkBorder = new CachedValue(() => _root.querySelectorAll('#location .content .gmap').toList(growable: false));

    _blinker = new Blinker(blinkDuration, blinkDownDuration, [
      new BlinkTarget(_blinkInput, frameBackground),
      new BlinkTarget(_blinkBorder, frameBorder, frameBorderStop)
    ]);
  }

  toggle(event) {
    final button = event.target as PaperIconButton;
    _logger.fine("Toggle edit: ${button.icon}");
    button.icon = isEditing ? editFlip : editFlop;

    if (isEditing) {
      _blinker.stop();
      new Future.delayed(_blinker.blinkStopDuration, () {
        isEditing = false;
      });
      _gmap.onClick = null;
    } else {
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
  }
}

class _PhotoSize {
  static const buttonsTimeout = const Duration(seconds: 5);

  final ShadowRoot _root;
  CachedValue<Element> _toolbar, _buttons;
  CachedValue<CoreAnimatedPages> _pages;

  Timer _buttonsTimer;
  bool _buttonsShow;

  _PhotoSize(this._root) {
    _toolbar = new CachedValue(() => _root.querySelector('core-toolbar'));
    _pages = new CachedValue(() => _root.querySelector('core-animated-pages'));
    _buttons = new CachedValue(() => _root.querySelector('#fullPhoto #buttons'));
  }

  int _width;
  int get width {
    if (_width == null) {
      final divNormal = _root.querySelector('#normal #photo');
      if (divNormal != null && 0 < divNormal.clientWidth) {
        _init(divNormal);
        _width = divNormal.clientWidth;
      }
    }
    return _width;
  }
  int get height => width;

  _init(Element divNormal) async {
    final fullHeight = _root.querySelector('#mainFrame').clientHeight;
    final divFullsize = _root.querySelector('#fullPhoto #photo');
    divFullsize.style.height = "${fullHeight}px";

    divNormal.onDoubleClick.listen((event) => _openFullsize());
    divFullsize.onClick.listen((event) => _showButtons());
  }

  _showButtons() {
    _logger.fine("show fullphoto buttons");
    if (_buttonsTimer != null) _buttonsTimer.cancel();
    _buttonsTimer = new Timer(buttonsTimeout, _hideButtons);
    if (!_buttonsShow) _animateButtons(_buttonsShow = true);
  }

  _hideButtons() {
    _logger.fine("hide fullphoto buttons");
    _animateButtons(_buttonsShow = false);
  }

  _animateButtons(bool show) {
    final move = _buttons.value.clientHeight;
    final list = [{'transform': "translateY(${-move}px)"}, {'transform': "none"}];
    final frames = show ? list : list.reversed.toList();

    new CoreAnimation()
      ..target = _buttons.value
      ..duration = 300
      ..fill = "forwards"
      ..keyframes = frames
      ..play();
  }

  _openFullsize() {
    _pages.value.selected = 1;
    _toolbar.value.style.display = "none";
    _showButtons();
  }

  closeFullsize() {
    _toolbar.value.style.display = "block";
    _pages.value.selected = 0;
  }
}

class _Conditions {
  final Loc.Condition _src;
  final OnChanged _onChanged;
  final _WeatherWrapper weather;
  final Getter<EditWeatherDialog> weatherDialog = new PipeValue();
  final Getter<EditTideDialog> tideDialog = new PipeValue();

  _Conditions(Loc.Condition src, OnChanged onChanged)
      : this._src = src,
        this._onChanged = onChanged,
        this.weather = new _WeatherWrapper(src.weather, onChanged);

  Loc.Tide get tide => _src.tide;
  set tide(Loc.Tide v) {
    _src.tide = v;
    _onChanged();
  }
  String get tideName => nameOfEnum(_src.tide);
  String get tideImage => Loc.Tides.iconOf(_src.tide);

  int get moon => _src.moon;
  String get moonImage => Loc.MoonPhases.iconOf(_src.moon);

  dialogWeather() => weatherDialog.value.open();
  dialogTide() => tideDialog.value.open();
}
class _WeatherWrapper implements Loc.Weather {
  final Loc.Weather _src;
  final OnChanged _onChanged;

  _WeatherWrapper(this._src, this._onChanged);

  Map get asMap => _src.asMap;
  String get asParam => _src.asParam;
  set asParam(String v) => _src.asParam = v;

  Future<TemperatureUnit> _temperatureUnit;
  Temperature _temperature;
  Temperature get temperature {
    if (_temperature == null && _temperatureUnit == null) {
      _temperatureUnit = UserPreferences.measures.then((m) => m.temperature);
      _temperatureUnit.then((unit) {
        _temperature = _src.temperature.convertTo(unit);
        _temperatureUnit = null;
      });
    }
    return _temperature;
  }
  set temperature(Temperature v) {
    if (v == null) return;
    if (_temperature != null && v.value == _temperature.value && v.unit == _temperature.unit) return;
    _src.temperature = v;
    _temperature = null;
    _onChanged();
  }

  String get nominal => _src.nominal;
  set nominal(String v) {
    if (v == null || _src.nominal == v) return;
    _src.nominal = v;
    _onChanged();
  }

  String get iconUrl => _src.iconUrl;
  set iconUrl(String v) {
    if (v == null || _src.iconUrl == v) return;
    _src.iconUrl = v;
    _onChanged();
  }
}
