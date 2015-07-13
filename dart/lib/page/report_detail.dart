library triton_note.page.report_detail;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_animation.dart';
import 'package:core_elements/core_animated_pages.dart';
import 'package:core_elements/core_header_panel.dart';
import 'package:paper_elements/paper_icon_button.dart';

import 'package:triton_note/dialog/edit_timestamp.dart';
import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/preferences.dart';
import 'package:triton_note/service/reports.dart';
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
  _PhotoSize photo;
  _GMap gmap;
  _Conditions conditions;
  GetterSetter<EditTimestampDialog> editTimestamp = new PipeValue();

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
      conditions = new _Conditions(report.condition);
      gmap = new _GMap(root, report.location.geoinfo);
    });
  }
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
