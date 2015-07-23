library triton_note.page.distributions;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_animated_pages.dart';
import 'package:core_elements/core_header_panel.dart';
import 'package:paper_elements/paper_action_dialog.dart';
import 'package:paper_elements/paper_tabs.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/element/distributions_filter.dart';
import 'package:triton_note/service/geolocation.dart' as Geo;
import 'package:triton_note/service/googlemaps_browser.dart';
import 'package:triton_note/util/main_frame.dart';
import 'package:triton_note/util/getter_setter.dart';

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

  DistributionsPage(Router router) : super(router);

  final Getter<DistributionsFilterElement> filter = new PipeValue();

  Getter<Element> scroller;
  Getter<Element> scrollBase;
  Getter<Element> _toolbar;

  Getter<CoreAnimatedPages> _pages;
  Getter<PaperTabs> _tabs;
  Getter<PaperActionDialog> _filterDialog;

  int _selectedTab;
  int get _selectedIndex => _selectedTab;
  set _selectedIndex(int v) => _pages.value.selected = _tabs.value.selected = _selectedTab = v;

  _Dmap dmap;

  void onShadowRoot(ShadowRoot sr) {
    super.onShadowRoot(sr);

    _pages = new CachedValue(() => root.querySelector('core-animated-pages'));
    scroller = new CachedValue(() => (root.querySelector('core-header-panel[main]') as CoreHeaderPanel).scroller);
    scrollBase = _pages;
    _toolbar = new CachedValue(() => root.querySelector('core-header-panel[main] core-toolbar'));
    _tabs = new CachedValue(() => root.querySelector('paper-tabs'));
    listenOn(_tabs.value, 'core-select', (event) {
      _pages.value.selected = _selectedTab = int.parse(_tabs.value.selected.toString());
      _logger.fine("Selected tab: ${_selectedTab}: ${selectedPage.id}");
    });
    _filterDialog = new CachedValue(() => root.querySelector('paper-action-dialog#distributions-filter'));

    dmap = new _Dmap(this);
  }

  Element get selectedPage => root.querySelectorAll("core-animated-pages section")[_selectedIndex];

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

class _Dmap {
  static GeoInfo lastPos;

  final DistributionsPage _parent;
  final Element _section;
  final Getter<GoogleMap> gmap = new PipeValue();

  GeoInfo pos;
  bool get isReady => pos == null;

  _Dmap(DistributionsPage parent)
      : this._parent = parent,
        this._section = parent.root.querySelector('core-animated-pages section#dmap') {
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
  }

  _initToolbar() => new Future.delayed(new Duration(milliseconds: 10), () {
    toggle(bool open) {
      if (open) {
        _parent._toolbar.value.style.display = "block";
      } else {
        _parent._toolbar.value.style.display = "none";
      }
    }
    _section.querySelector('#gmap expandable-gmap')
      ..on['expanding'].listen((event) => toggle(false))
      ..on['shrinking'].listen((event) => toggle(true));
  });
}
