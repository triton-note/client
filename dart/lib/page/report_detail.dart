library triton_note.page.report_detail;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_animation.dart';
import 'package:core_elements/core_animated_pages.dart';
import 'package:core_elements/core_header_panel.dart';
import 'package:paper_elements/paper_icon_button.dart';

import 'package:triton_note/dialog/edit_fish.dart';
import 'package:triton_note/dialog/edit_timestamp.dart';
import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/preferences.dart';
import 'package:triton_note/service/reports.dart';
import 'package:triton_note/service/server.dart';
import 'package:triton_note/service/googlemaps_browser.dart';
import 'package:triton_note/util/enums.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('ReportDetailPage');

const String editFlip = "create";
const String editFlop = "done";

@Component(
    selector: 'report-detail',
    templateUrl: 'packages/triton_note/page/report_detail.html',
    cssUrl: 'packages/triton_note/page/report_detail.css',
    useShadowDom: true)
class ReportDetailPage extends MainFrame {
  Future<Report> _report;
  Report report;
  _Catches catches;
  _PhotoSize photo;
  _GMap gmap;
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
      catches = new _Catches(root, new GetterSetter(() => report.fishes, (v) => report.fishes = v));
      conditions = new _Conditions(report.condition);
      gmap = new _GMap(root, report.location.geoinfo);
    });
  }

  void onChanged() {
    if (submitTimer != null && submitTimer.isActive) submitTimer.cancel();
    submitTimer = new Timer(new Duration(seconds: 30), () {
      Server.update(report);
    });
  }
}

class _Catches {
  static const frameButton = const [const {'opacity': 0.05}, const {'opacity': 1}];
  static const frameItem = const [const {'background': "#fffcfc"}, const {'background': "#fee"}];
  static const Duration blinkDuration = const Duration(seconds: 2);
  static const Duration blinkDownDuration = const Duration(milliseconds: 300);

  final ShadowRoot _root;
  final GetterSetter<List<Fishes>> list;
  GetterSetter<EditFishDialog> dialog = new PipeValue();
  bool isEditing = false;
  Timer _blinkTimer;
  List<CoreAnimation> _animations;

  _Catches(this._root, this.list);

  toggle(event) {
    final button = event.target as PaperIconButton;
    _logger.fine("Toggle edit: ${button.icon}");
    button.icon = isEditing ? editFlip : editFlop;

    final CachedValue<Element> addButton = new CachedValue(() => _root.querySelector('#fishes paper-icon-button.add'));
    final CachedValue<ElementList<Element>> fishItems =
        new CachedValue(() => _root.querySelectorAll('#fishes div.item'));

    blink(final bool updown,
        {final duration: blinkDuration, final repeat: true, frameItem: frameItem, frameButton: frameButton}) {
      _animations = [];

      animate(Element target, List frames) {
        final keyframes = updown ? frames : frames.reversed.toList();
        _logger.finest("Blink: ${target}: ${keyframes}");
        final a = new CoreAnimation()
          ..target = target
          ..duration = duration.inMilliseconds
          ..keyframes = keyframes
          ..fill = "forwards"
          ..easing = "ease-in-out"
          ..play();
        _animations.add(a);
      }
      animate(addButton.value, frameButton);
      fishItems.value.forEach((item) {
        animate(item, frameItem);
      });
      if (repeat) _blinkTimer = new Timer(blinkDuration, () => blink(!updown));
    }

    if (isEditing) {
      _logger.finest("Blink stopping...");
      if (_blinkTimer != null && _blinkTimer.isActive) _blinkTimer.cancel();
      if (_animations != null) _animations.forEach((a) => a.cancel());
      blink(false,
          duration: blinkDownDuration, repeat: false, frameItem: [{'background': "white"}, {'background': "#fee"}]);
      new Future.delayed(blinkDownDuration, () {
        isEditing = false;
      });
    } else {
      isEditing = true;
      new Future.delayed(new Duration(milliseconds: 10), () {
        blink(true);

        fishItems.value.forEach((item) {
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
    }));
  });
}

class _GMap {
  final ShadowRoot _root;
  final GeoInfo geoinfo;
  Getter<Element> getScroller;
  Getter<Element> getBase;
  Setter<GoogleMap> setGMap;
  GoogleMap _gmap;

  _GMap(this._root, this.geoinfo) {
    getBase = new Getter<Element>(() => _root.querySelector('#base'));
    getScroller = new Getter<Element>(() {
      final panel = _root.querySelector('core-header-panel[main]') as CoreHeaderPanel;
      return (panel == null) ? null : panel.scroller;
    });
    setGMap = new Setter<GoogleMap>((v) {
      _gmap = v;
      _gmap.putMarker(geoinfo);
    });
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
  final Condition src;

  _Conditions(this.src);

  String get tideName => nameOfEnum(src.tide);
  String get tideImage => Tides.iconOf(src.tide);

  int get moon => src.moon;
  String get moonImage => MoonPhases.iconOf(src.moon);

  Weather get weather => src.weather;

  Temperature _temperature;
  Temperature get temperature {
    if (_temperature == null) {
      _temperature = src.weather.temperature.convertTo(UserPreferences.temperatureUnit);
    }
    return _temperature;
  }
}
