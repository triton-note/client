library triton_note.page.distributions;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_animated_pages.dart';
import 'package:core_elements/core_header_panel.dart';
import 'package:paper_elements/paper_tabs.dart';

import 'package:triton_note/dialog/edit_timestamp.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/service/geolocation.dart' as Geo;
import 'package:triton_note/service/googlemaps_browser.dart';
import 'package:triton_note/service/preferences.dart';
import 'package:triton_note/util/main_frame.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/enums.dart';

final _logger = new Logger('DistributionsPage');

@Component(
    selector: 'distributions',
    templateUrl: 'packages/triton_note/page/distributions.html',
    cssUrl: 'packages/triton_note/page/distributions.css',
    useShadowDom: true)
class DistributionsPage extends MainFrame {
  static const DMAP = 0;
  static const DTIME = 1;
  static const DRATE = 2;

  CachedValue<CoreAnimatedPages> _pages;
  CachedValue<PaperTabs> _tabs;

  int _selectedTab;
  int get _selectedIndex => _selectedTab;
  set _selectedIndex(int v) => _pages.value.selected = _tabs.value.selected = _selectedTab = v;

  String get lengthUnit => nameOfEnum(CachedMeasures.lengthUnit);
  String get weightUnit => nameOfEnum(CachedMeasures.weightUnit);

  _Dmap dmap;

  DistributionsPage(Router router) : super(router);

  void onShadowRoot(ShadowRoot sr) {
    super.onShadowRoot(sr);

    Timer timer = null;
    _pages = new CachedValue(() => root.querySelector('core-animated-pages'));
    _tabs = new CachedValue(() => root.querySelector('paper-tabs'));
    _tabs.value.on['core-select'].listen((event) {
      final tabs = event.target;
      if (tabs is PaperTabs) {
        if (timer != null && timer.isActive) timer.cancel();
        timer = new Timer(new Duration(milliseconds: 100), () {
          _pages.value.selected = _selectedTab = int.parse(tabs.selected.toString());
          _logger.fine("Selected tab: ${_selectedTab}: ${selectedPage.id}");
        });
      }
    });

    dmap = new _Dmap(root);
  }

  Element get selectedPage => root.querySelectorAll("core-animated-pages section")[_selectedIndex];

  void options() {
    _logger.finest("Click options");
  }
}

enum _RecentUnit { days, weeks, months }

class _Dmap {
  static const toolbarDuration = const Duration(milliseconds: 200);
  static GeoInfo lastPos;

  final ShadowRoot _root;
  final Getter<GoogleMap> gmap = new PipeValue();
  Getter<Element> scroller;
  Getter<Element> base;
  Getter<Element> _toolbar;

  GeoInfo pos;
  bool get isReady => pos == null;

  // Options

  // size
  int sizeMinLength = 0;
  bool get sizeMinLengthActive => sizeMinLength > 0;
  int sizeMaxLength = 0;
  bool get sizeMaxLengthActive => sizeMaxLength > sizeMinLength;
  bool get sizeLengthActive => sizeMinLengthActive || sizeMaxLengthActive;

  int sizeMinWeight = 0;
  bool get sizeMinWeightActive => sizeMinWeight > 0;
  int sizeMaxWeight = 0;
  bool get sizeMaxWeightActive => sizeMaxWeight > sizeMinWeight;
  bool get sizeWeightActive => sizeMinWeightActive || sizeMaxWeightActive;

  int recentValue;
  String recentUnitName = nameOfEnum(_RecentUnit.values.first);
  _RecentUnit get recentUnit => enumByName(_RecentUnit.values, recentUnitName);
  final List<String> recentUnitList = _RecentUnit.values.map(nameOfEnum);

  int seasonBegin = 1;
  int seasonEnd = 2;

  DateTime termFrom = new DateTime.now();
  Getter<EditTimestampDialog> termFromDialog = new PipeValue();
  DateTime termTo = new DateTime.now();
  Getter<EditTimestampDialog> termToDialog = new PipeValue();

  _Dmap(this._root) {
    if (lastPos == null) {
      Geo.location().then((v) {
        pos = lastPos = v;
        _initToolbar();
      });
    } else {
      new Future.delayed(new Duration(milliseconds: 300), () {
        pos = lastPos;
        _initToolbar();
      });
    }

    scroller = new CachedValue(() => (_root.querySelector('core-header-panel[main]') as CoreHeaderPanel).scroller);
    base = new CachedValue(() => _root.querySelector('core-header-panel[main] core-animated-pages'));
    _toolbar = new CachedValue(() => _root.querySelector('core-header-panel[main] core-toolbar'));
  }

  _initToolbar() => new Future.delayed(new Duration(milliseconds: 10), () {
    toggle(bool open) {
      if (open) {
        _toolbar.value.style.display = "block";
      } else {
        _toolbar.value.style.display = "none";
      }
    }
    _root.querySelector('#dmap #gmap expandable-gmap')
      ..on['expanding'].listen((event) => toggle(false))
      ..on['shrinking'].listen((event) => toggle(true));
  });
}
