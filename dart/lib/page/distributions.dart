library triton_note.page.distributions;

import 'dart:async';
import 'dart:html';
import 'dart:collection';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_animated_pages.dart';
import 'package:core_elements/core_header_panel.dart';
import 'package:paper_elements/paper_tabs.dart';

import 'package:triton_note/dialog/distributions_filter.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/service/geolocation.dart' as Geo;
import 'package:triton_note/service/googlemaps_browser.dart';
import 'package:triton_note/service/catches.dart';
import 'package:triton_note/util/distributions_filters.dart';
import 'package:triton_note/util/icons.dart';
import 'package:triton_note/util/enums.dart';
import 'package:triton_note/util/chart.dart' as chart;
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
  final Getter<DistributionsFilterDialog> filterDialog = new PipeValue();

  Getter<Element> scroller;
  Getter<Element> scrollBase;
  Getter<Element> toolbar;

  Getter<CoreAnimatedPages> _pages;
  Getter<PaperTabs> _tabs;

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
  final Completer<Null> _onReady = new Completer();
  bool get isReady => _onReady.isCompleted;

  void onShadowRoot(ShadowRoot sr) {
    super.onShadowRoot(sr);

    _pages = new CachedValue(() => root.querySelector('core-animated-pages'));
    scroller = new CachedValue(() => (root.querySelector('core-header-panel[main]') as CoreHeaderPanel).scroller);
    scrollBase = _pages;
    toolbar = new CachedValue(() => root.querySelector('core-header-panel[main] core-toolbar'));
    _tabs = new CachedValue(() => root.querySelector('core-toolbar paper-tabs'));
    filterDialog.value.onClossing(_refresh);

    sections = [dmap = new _DMap(this), dtime = new _DTimeLine(this)];

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

    _tabReady();
  }

  _tabReady() async {
    await Future.wait(sections.map((s) => s._onReady.future).toList());
    _onReady.complete();

    final dur = const Duration(milliseconds: 100);
    listen() {
      if (_tabs.value != null) {
        listenOn(_tabs.value, 'core-select', (target) {
          _pages.value.selected = _selectedTab = int.parse(target.selected.toString());
          _logger.fine("Selected tab: ${_selectedTab}: ${selectedPage.id}");
        });
      } else {
        new Future.delayed(dur, listen);
      }
    }
    listen();
  }

  void detach() {
    dmap.detach();
    dtime.detach();
  }

  openFilter() => filterDialog.value.open();

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
  final Completer<Null> _onReady = new Completer();

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

  bool get isReady => _onReady.isCompleted;
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
      if (!_onReady.isCompleted) _onReady.complete();

      _logger.finer(() => "Map moved: ${_lastCenter}, ${_bounds}");
      if (_refreshTimer != null && _refreshTimer.isActive) _refreshTimer.cancel();
      _refreshTimer = (_bounds == null) ? null : new Timer(refreshDur, _parent._refresh);
    });
  }

  refresh() async {
    _chooses.keys.toList().forEach((index) {
      _chooses[index].remove();
      _chooses.remove(index);
    });
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

  static const Map<String, String> selections = const {
    'HOUR': 'Hours in Day',
    'MONTH': 'Months in Year',
    'MOON': 'by Moon age',
    'TIDE': 'by Tide'
  };

  static const List<String> nameOfMonths = const [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];

  static const List<List<int>> colors = const [
    const [223, 223, 223],
    const [239, 143, 47],
    const [143, 239, 47],
    const [47, 143, 239]
  ];

  _DTimeLine(DistributionsPage parent) : super(parent, 'dtime') {
    _onReady.complete();
  }

  DivElement get chartHost => _section.querySelector('#chart');
  bool get isCalculating => labels == null;

  List<String> get selectionNames => selections.keys;
  String selection(String key) => selections[key];

  String _selected;
  void select(String v) {
    _logger.finest(() => "Selected: ${v}");
    if (selections.containsKey(v)) {
      _selected = v;
      refresh();
    }
  }

  List<Map<String, String>> labels = [];

  refresh() async {
    _logger.finest(() => "Refreshing...");
    _calculate(_selected);
  }

  void detach() {}

  activated() {
    final height = window.innerHeight - chartHost.getBoundingClientRect().top.round() - 4;
    chartHost.style.height = "${height}px";
    refresh();
  }

  CanvasRenderingContext2D get _canvas {
    chartHost.querySelector("canvas")?.remove();

    final canvas = document.createElement("canvas") as CanvasElement
      ..width = chartHost.clientWidth
      ..height = chartHost.clientHeight;

    chartHost.children.insert(0, canvas);
    return canvas.context2D;
  }

  _draw(chart.Data data) async {
    _logger.fine(() => "Drawing chart to canvas");
    new chart.Chart(_canvas).Line(data, new chart.Options(responsive: true));
  }

  Future<Map<String, List<Catches>>> _getTop3() async {
    final List<Catches> allList = await _catchesList;

    final result = new LinkedHashMap();
    result['Total'] = allList;

    if (_parent.filter.value.fish.isActiveName) {
      final Map<String, List<Catches>> store = {};
      final Map<String, int> counter = {};
      capitalize(String text) => text[0].toUpperCase() + text.substring(1).toLowerCase();

      allList.forEach((c) {
        final key = capitalize(c.fish.name);
        final list = store[key] ?? [];
        list.add(c);
        store[key] = list;
        counter[key] = (counter[key] ?? 0) + c.fish.count;
      });
      final sorted = store.keys.toList()..sort((a, b) => counter[a] - counter[b]);
      if (sorted.length > 3) sorted.sublist(3).forEach((key) {
        store.remove(key);
      });
      sorted.take(3).forEach((key) {
        result[key] = store[key];
      });
    }
    return result;
  }

  _drawData(List<String> keys, String keyOf(Catches c)) async {
    final top3 = await _getTop3();
    final sets = [];
    top3.keys.forEach((label) {
      final data = new List.filled(keys.length, 0);
      top3[label].forEach((c) {
        final index = keys.indexOf(keyOf(c));
        if (index >= 0) data[index] = data[index] + c.fish.count;
      });
      _logger.finer(() => "Making DataSet: ${label}: ${data}");

      rgba([double a = 1.0]) => "rgba(${colors[sets.length].join(',')},${a})";
      sets.add(new chart.DataSet(
          label: label,
          fillColor: rgba(0.2),
          strokeColor: rgba(),
          pointColor: rgba(),
          pointStrokeColor: "#fff",
          pointHighlightFill: "#fff",
          pointHighlightStroke: rgba(),
          data: data));
    });

    labels = sets.map((ds) => {'color': ds.strokeColor, 'label': ds.label}).toList();
    _logger.finer(() => "Completing making data: ${keys}, ${labels}");

    _draw(new chart.Data(labels: keys, datasets: sets));
  }

  _calculate(String way) async {
    labels = null;

    _calcHour() {
      _logger.info(() => "Calculating count by hour...");
      _drawData(new List.generate(24, (i) => "${i}"), (c) => "${c.dateAt.hour}");
    }
    _calcMonth() {
      _logger.info(() => "Calculating count by month...");
      int begin = 0, end = 11;
      if (_parent.filter.value.term.isActiveSeason) {
        begin = _parent.filter.value.term.seasonBegin - 1;
        end = _parent.filter.value.term.seasonEnd - 1;
      }
      final keys = new List.generate(end - begin + 1, (i) => nameOfMonths[i + begin]);
      _drawData(keys, (c) => nameOfMonths[c.dateAt.month - 1]);
    }
    _calcMoon() {
      _logger.info(() => "Calculating count by moon...");
      _drawData(new List.generate(30, (i) => "${i}"), (c) => "${c.condition.moon}");
    }
    _calcTide() {
      _logger.info(() => "Calculating count by tide...");
      final keys = [Tide.Ebb, Tide.Low, Tide.Flood, Tide.High].map((x) => nameOfEnum(x)).toList();
      _drawData(keys, (c) => nameOfEnum(c.condition.tide));
    }

    switch (way) {
      case 'HOUR':
        _calcHour();
        break;
      case 'MONTH':
        _calcMonth();
        break;
      case 'MOON':
        _calcMoon();
        break;
      case 'TIDE':
        _calcTide();
        break;
      default:
        labels = [];
    }
  }
}
