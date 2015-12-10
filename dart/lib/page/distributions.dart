library triton_note.page.distributions;

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_animated_pages.dart';
import 'package:core_elements/core_header_panel.dart';
import 'package:paper_elements/paper_dialog.dart';
import 'package:paper_elements/paper_tabs.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/service/geolocation.dart' as Geo;
import 'package:triton_note/service/googlemaps_browser.dart';
import 'package:triton_note/service/catches.dart';
import 'package:triton_note/util/distributions_filters.dart';
import 'package:triton_note/util/icons.dart';
import 'package:triton_note/util/chart.dart';
import 'package:triton_note/util/main_frame.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/pager.dart';

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
  Getter<PaperDialog> _filterDialog;

  int _selectedTab;
  int get _selectedIndex => _selectedTab;
  set _selectedIndex(int v) => _pages.value.selected = _tabs.value.selected = _selectedTab = v;
  Element get selectedPage => root.querySelectorAll("core-animated-pages section")[_selectedIndex];

  PagingList<Catches> catchesPager;
  Future<List<Catches>> get _catchesList async {
    while (catchesPager.hasMore) {
      await catchesPager.more(100);
    }
    return catchesPager.list;
  }

  _DMap dmap;
  _DTimeLine dtime;
  List<_Section> sections;

  void onShadowRoot(ShadowRoot sr) {
    super.onShadowRoot(sr);

    _pages = new CachedValue(() => root.querySelector('core-animated-pages'));
    scroller = new CachedValue(() => (root.querySelector('core-header-panel[main]') as CoreHeaderPanel).scroller);
    scrollBase = _pages;
    toolbar = new CachedValue(() => root.querySelector('core-header-panel[main] core-toolbar'));
    _tabs = new CachedValue(() => root.querySelector('core-toolbar paper-tabs'));
    _filterDialog = new CachedValue(() => root.querySelector('paper-dialog#distributions-filter'));

    sections = [dmap = new _DMap(this), dtime = new _DTimeLine(this)];

    listenOn(_tabs.value, 'core-select', (target) {
      _pages.value.selected = _selectedTab = int.parse(target.selected.toString());
      _logger.fine("Selected tab: ${_selectedTab}: ${selectedPage.id}");
    });
    _pages.value.on['core-animated-pages-transition-prepare'].listen((event) {
      sections.forEach((s) {
        if (s.id != selectedPage.id) s.inactivating();
        else s.activating();
      });
    });
    _pages.value.on['core-animated-pages-transition-end'].listen((event) {
      sections.forEach((s) {
        if (s.id != selectedPage.id) s.inactivated();
        else s.activated();
      });
    });
  }

  void detach() {
    dmap.detach();
    dtime.detach();
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
      ..open();
  }

  void closeFilter() {
    closeDialog(_filterDialog.value);
    _refresh();
  }

  _refresh() async {
    _logger.finer("Refreshing list around: ${dmap._bounds}, ${catchesPager}");
    catchesPager = new PagingList(await Catches.inArea(dmap._bounds, filter.value));
    sections.forEach((s) {
      s.refresh();
    });
  }
}

abstract class _Section {
  final DistributionsPage _parent;
  final Element _section;
  final String id;

  _Section(DistributionsPage parent, String id)
      : this._parent = parent,
        this.id = id,
        this._section = parent.root.querySelector("core-animated-pages > section#${id}");

  PagingList<Catches> get _catchesPager => _parent.catchesPager;
  Future<List<Catches>> get _catchesList => _parent._catchesList;

  void detach();

  refresh();

  activating() {}
  activated() {}

  inactivating() {}
  inactivated() {}
}

class _DMap extends _Section {
  static final _logger = new Logger('DistributionsPage.Map');

  static const refreshDur = const Duration(seconds: 2);
  static GeoInfo _lastCenter;

  _DMap(DistributionsPage parent) : super(parent, 'dmap') {
    _logger.fine("Creating ${this}: lastPos=${_lastCenter}");
    if (_lastCenter == null) {
      Geo.location().then((v) {
        _lastCenter = v;
      });
    }
    gmapSetter.future.then(_initGMap);
  }

  final FuturedValue<GoogleMap> gmapSetter = new FuturedValue();

  LatLngBounds _bounds;
  GeoInfo get center => _lastCenter;
  Timer _refreshTimer;
  HeatmapLayer _heatmap;
  bool _isHeated = false;
  Map<int, Marker> _chooses = {};

  _initGMap(GoogleMap gmap) {
    _logger.info("Setting GoogeMap up");
    _section.querySelector('#gmap expandable-gmap')
      ..on['expanding'].listen((event) => gmap.options.mapTypeControl = true)
      ..on['shrinking'].listen((event) => gmap.options.mapTypeControl = false);

    gmap.showMyLocationButton = true;

    gmap.addCustomIcon((img) {
      img
        ..style.borderRadius = '12px'
        ..src = ICON_FIRE_MONO
        ..onClick.listen((_) {
          img.style.backgroundColor = _isHeated ? 'transparent' : 'red';
          _isHeated = !_isHeated;
          _logger.finer("Show heatmap: ${_isHeated}");
          _showHeatmap();
        });
    });

    gmap.on('bounds_changed', () {
      _lastCenter = gmap.center;
      _bounds = gmap.bounds;
      _logger.finer(() => "Map moved: ${_lastCenter}, ${_bounds}");
      if (_refreshTimer != null && _refreshTimer.isActive) _refreshTimer.cancel();
      _refreshTimer = (_bounds == null) ? null : new Timer(refreshDur, _parent._refresh);
    });
  }

  refresh() async {
    _section.click();
    _showHeatmap();
  }

  void detach() {
    if (_refreshTimer != null && _refreshTimer.isActive) _refreshTimer.cancel();
  }

  _showHeatmap() async {
    if (_isHeated) {
      final data = (await _catchesList).map((Catches c) => {'location': c.location.geoinfo, 'weight': c.fish.count});
      _heatmap?.setMap(null);
      _heatmap = new HeatmapLayer(data);
      _heatmap.setMap(await gmapSetter.future);
    } else {
      _heatmap?.setMap(null);
    }
  }

  bool operator [](int index) => _chooses.containsKey(index);
  operator []=(int index, bool opened) async {
    _logger.finest(() => "Choose catches: ${index}=${opened}");
    if (opened) {
      final gmap = await gmapSetter.future;
      final marker = gmap.putMarker(_catchesPager.list[index].location.geoinfo);
      _chooses[index] = marker;
    } else {
      _chooses[index]?.remove();
      _chooses.remove(index);
    }
  }
}

class _DTimeLine extends _Section {
  static final _logger = new Logger('DistributionsPage.TimeLine');

  static const selections = const {
    'HOUR': 'Hours in Day',
    'MONTH': 'Months in Year',
    'MOON': 'by Moon age',
    'TIDE': 'by Tide'
  };

  _DTimeLine(DistributionsPage parent) : super(parent, 'dtime');

  bool isCalculating = false;

  List<String> get selectionNames => selections.keys;
  String selection(String key) => selections[key];

  String _selected;
  void select(String v) {
    _logger.finest(() => "Selected: ${v}");
    if (selections.contains(v)) {
      _selected = v;
    }
  }

  refresh() async {}

  void detach() {}

  activated() {
    _show(_section.querySelector('#chart .canvas'));
  }

  inactivated() {
    _section.querySelector('#chart .canvas canvas')?.remove();
  }

  void _show(DivElement host) {
    final hostW = host.clientWidth;
    final canvas = document.createElement('canvas') as CanvasElement
      ..style.marginLeft = '4px'
      ..width = hostW - 4
      ..height = (hostW * 2 / (1 + sqrt(5))).round() + 32;
    host.append(canvas);
    final ctx = canvas.context2D;

    final rnd = new Random();

    final data = new Data(labels: [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July"
    ], datasets: <DataSet>[
      new DataSet(
          label: "My First dataset",
          fillColor: "rgba(220,220,220,0.2)",
          strokeColor: "rgba(220,220,220,1)",
          pointColor: "rgba(220,220,220,1)",
          pointStrokeColor: "#fff",
          pointHighlightFill: "#fff",
          pointHighlightStroke: "rgba(220,220,220,1)",
          data: [
            rnd.nextInt(100),
            rnd.nextInt(100),
            rnd.nextInt(100),
            rnd.nextInt(100),
            rnd.nextInt(100),
            rnd.nextInt(100),
            rnd.nextInt(100)
          ]),
      new DataSet(
          label: "My Second dataset",
          fillColor: "rgba(151,187,205,0.2)",
          strokeColor: "rgba(151,187,205,1)",
          pointColor: "rgba(151,187,205,1)",
          pointStrokeColor: "#fff",
          pointHighlightFill: "#fff",
          pointHighlightStroke: "rgba(151,187,205,1)",
          data: [
            rnd.nextInt(100),
            rnd.nextInt(100),
            rnd.nextInt(100),
            rnd.nextInt(100),
            rnd.nextInt(100),
            rnd.nextInt(100),
            rnd.nextInt(100)
          ])
    ]);

    new Chart(ctx).Line(data, new Options(responsive: true));
  }
}
