library triton_note.page.distributions;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_animated_pages.dart';
import 'package:core_elements/core_header_panel.dart';
import 'package:paper_elements/paper_action_dialog.dart';
import 'package:paper_elements/paper_tabs.dart';
import 'package:paper_elements/paper_toggle_button.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/service/geolocation.dart' as Geo;
import 'package:triton_note/service/googlemaps_browser.dart';
import 'package:triton_note/service/catches.dart';
import 'package:triton_note/util/distributions_filters.dart';
import 'package:triton_note/util/main_frame.dart';
import 'package:triton_note/util/getter_setter.dart';

final _logger = new Logger('DistributionsPage');

@Component(
    selector: 'distributions',
    templateUrl: 'packages/triton_note/page/distributions.html',
    cssUrl: 'packages/triton_note/page/distributions.css',
    useShadowDom: true)
class DistributionsPage extends MainFrame implements DetachAware {
  DistributionsPage(Router router) : super(router);

  final Getter<DistributionsFilter> filter = new PipeValue();

  Getter<Element> scroller;
  Getter<Element> scrollBase;
  Getter<Element> toolbar;

  Getter<CoreAnimatedPages> _pages;
  Getter<PaperTabs> _tabs;
  Getter<PaperActionDialog> _filterDialog;

  int _selectedTab;
  int get _selectedIndex => _selectedTab;
  set _selectedIndex(int v) => _pages.value.selected = _tabs.value.selected = _selectedTab = v;
  Element get selectedPage => root.querySelectorAll("core-animated-pages section")[_selectedIndex];

  _Dmap dmap;

  void onShadowRoot(ShadowRoot sr) {
    super.onShadowRoot(sr);

    _pages = new CachedValue(() => root.querySelector('core-animated-pages'));
    scroller = new CachedValue(() => (root.querySelector('core-header-panel[main]') as CoreHeaderPanel).scroller);
    scrollBase = _pages;
    toolbar = new CachedValue(() => root.querySelector('core-header-panel[main] core-toolbar'));
    _tabs = new CachedValue(() => root.querySelector('paper-tabs'));
    listenOn(_tabs.value, 'core-select', (target) {
      _pages.value.selected = _selectedTab = int.parse(target.selected.toString());
      _logger.fine("Selected tab: ${_selectedTab}: ${selectedPage.id}");
    });
    _filterDialog = new CachedValue(() => root.querySelector('paper-action-dialog#distributions-filter'));

    dmap = new _Dmap(this);
  }

  void detach() {
    dmap.detach();
  }

  void openFilter(event) {
    final button = event.target as Element;
    _logger.finest("Open filter dialog");
    _filterDialog.value
      ..shadowRoot.querySelector('#scroller').style.padding = "0"
      ..style.margin = "0"
      ..style.top = "${button.getBoundingClientRect().bottom}px"
      ..style.left = "0"
      ..style.right = "0"
      ..toggle();
  }
}

abstract class _Section {
  final DistributionsPage _parent;
  final Element _section;

  _Section(DistributionsPage parent, String id)
      : this._parent = parent,
        this._section = parent.root.querySelector("core-animated-pages section#${id}");

  void detach();
}

class _Dmap extends _Section {
  static const refreshDur = const Duration(seconds: 3);
  static GeoInfo _lastCenter;

  _Dmap(DistributionsPage parent) : super(parent, 'dmap') {
    _logger.fine("Creating ${this}: lastPos=${_lastCenter}");
    if (_lastCenter == null) {
      Geo.location().then((v) {
        _lastCenter = v;
      });
    }
    gmapSetter.future.then(_initGMap);
  }

  final FuturedValue<GoogleMap> gmapSetter = new FuturedValue();

  GeoInfo get center => _lastCenter;
  bool get isReady => center == null;
  List<Catches> listAround;
  Timer _refreshTimer;

  _initGMap(GoogleMap gmap) {
    _logger.info("Setting GoogeMap up");
    _section.querySelector('#gmap expandable-gmap')
      ..on['expanding'].listen((event) => gmap.options.mapTypeControl = true)
      ..on['shrinking'].listen((event) => gmap.options.mapTypeControl = false);

    dragend() {
      _lastCenter = gmap.center;
      final bounds = gmap.bounds;
      _logger.finer(() => "Map moved: ${_lastCenter}, ${bounds}");
      if (_refreshTimer != null && _refreshTimer.isActive) _refreshTimer.cancel();
      _refreshTimer = (bounds == null) ? null : new Timer(refreshDur, () => _refresh(bounds));
    }
    gmap.on('dragend', dragend);
    new Future.delayed(new Duration(seconds: 1), dragend);
  }

  _refresh(LatLngBounds bounds) async {
    _logger.finer("Refreshing list around: ${bounds}, ${listAround}");
    listAround = null;
    listAround = await Catches.inArea(bounds, _parent.filter.value);
    _logger.finer(() => "List in around: ${listAround}");
  }

  toggleDensity(Event event) {
    final target = event.target as PaperToggleButton;
    _logger.finer("Toggle map density: ${target.checked}");
  }

  void detach() {
    if (_refreshTimer != null && _refreshTimer.isActive) _refreshTimer.cancel();
  }
}
