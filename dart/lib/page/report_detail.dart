library triton_note.page.report_detail;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_animated_pages.dart';
import 'package:core_elements/core_header_panel.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/reports.dart';
import 'package:triton_note/service/googlemaps_browser.dart';
import 'package:triton_note/util/enums.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('ReportDetailPage');

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

class UserPreferences {
  static LengthUnit get lengthUnit => LengthUnit.cm;
  static WeightUnit get weightUnit => WeightUnit.kg;
  static TemperatureUnit get temperatureUnit => TemperatureUnit.Cels;
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
  final ShadowRoot _root;

  _PhotoSize(this._root);

  CoreAnimatedPages get pages => _root.querySelector('core-animated-pages');
  Element get divNormal => _root.querySelector('#normal #photo');
  Element get divFullsize => _root.querySelector('#fullPhoto #photo');
  Element get toolbar => _root.querySelector('core-toolbar');
  Element get fullToolbar => _root.querySelector('#fullPhoto #toolbar');

  int _width;
  int get width {
    if (_width == null) {
      if (divNormal != null && 0 < divNormal.clientWidth) {
        _init();
        _width = divNormal.clientWidth;
      }
    }
    return _width;
  }
  int get height => width;

  _init() async {
    final height = window.screen.height;
    _logger.fine("Full height: ${height}");
    divFullsize.style.height = "${height}px";

    divNormal.onDoubleClick.listen((event) {
      pages.selected = 1;
      toolbar.style.display = "none";
    });

    divFullsize.onClick.listen((event) {
      fullToolbar.style.display = "block";
    });
  }

  closeFullsize() {
    toolbar.style.display = "block";
    pages.selected = 0;
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
