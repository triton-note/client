library triton_note.element.expandable_gmap;

import 'dart:async';
import 'dart:html';
import 'dart:math' as Math;

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_animation.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/icons.dart';
import 'package:triton_note/util/main_frame.dart';
import 'package:triton_note/service/googlemaps_browser.dart';

final _logger = new Logger('ExpandableGMapElement');

@Component(
    selector: 'expandable-gmap',
    templateUrl: 'packages/triton_note/element/expandable_gmap.html',
    cssUrl: 'packages/triton_note/element/expandable_gmap.css',
    useShadowDom: true)
class ExpandableGMapElement extends Backable implements ShadowRootAware, DetachAware {
  static const animationDur = const Duration(milliseconds: 300);

  @NgAttr('nofix-scroll') String nofixScroll; // Optional (default: false, means fix scroll on expanded)
  @NgOneWay('shrinked-height') int shrinkedHeight; // Optional (default: golden ratio of width)
  @NgOneWay('expanded-height') int expandedHeight; // Optional (default: max of base height)
  @NgOneWay('set-gmap') Setter<GoogleMap> setGMap; // Optional (no callback if null)
  @NgOneWay('get-scroller') Getter<Element> getScroller;
  @NgOneWay('get-base') Getter<Element> getBase;
  @NgOneWay('get-toolbar') Getter<Element> getToolbar; // Optional (default: null, means toolbar does not hide)
  @NgOneWay('center') GeoInfo center;

  ShadowRoot _root;
  int shrinkedHeightReal;
  bool isExpanded = false;
  int toolbarOriginalHeight;
  GeoInfo _curCenter;
  double _curZoom;
  bool _isChanging = false;

  Element get gmapHost => _root?.querySelector('#google-maps');

  Completer<GoogleMap> _gmapReady;
  bool get isReady {
    if (_gmapReady == null && center != null && shrinkedHeightReal != null) {
      _gmapReady = new Completer();
      _logger.finest(() => "Making google maps...");

      makeGoogleMap(gmapHost, center).then((gmap) {
        _gmapReady.complete(gmap);
        if (setGMap != null) setGMap.value = gmap;

        _curCenter = gmap.center;
        gmap.on('center_changed', () {
          if (!_isChanging) _curCenter = gmap.center;
        });
        _curZoom = gmap.zoom;
        gmap.on('zoom_changed', () {
          if (!_isChanging) _curZoom = gmap.zoom;
        });

        gmap.addCustomIcon((img) {
          _toggle = (_) async {
            img.src = isExpanded ? ICON_EXPAND : ICON_SHRINK;
            _isChanging = true;
            _root.host.dispatchEvent(new Event(isExpanded ? 'shrinking' : 'expanding'));
            _doToggle();
          };
          img
            ..src = ICON_EXPAND
            ..onClick.listen(_toggle);
        });
      });
    }
    return _gmapReady?.isCompleted ?? false;
  }

  @override
  void onShadowRoot(ShadowRoot sr) {
    _root = sr;

    int preWidth;
    final dur = new Duration(milliseconds: 30);
    checkWidth() {
      _checkingTimer = new Timer(dur, () {
        final w = gmapHost.clientWidth;
        _logger.finest("Checking width of host div: ${w}");
        if (w > 0) {
          if (w != preWidth) {
            preWidth = w;
          } else {
            shrinkedHeightReal = (shrinkedHeight != null) ? shrinkedHeight : (w * 2 / (1 + Math.sqrt(5))).round();
            _logger.fine("Shrinked height: ${shrinkedHeightReal}");
            gmapHost.style.height = "${shrinkedHeightReal}px";
          }
        }
        if (shrinkedHeightReal == null) checkWidth();
        else _checkingTimer == null;
      });
    }
    checkWidth();
  }

  Timer _checkingTimer;

  void detach() {
    _checkingTimer?.cancel();
  }

  backButton() {
    if (isExpanded) _toggle();
  }

  var _toggle;

  _doToggle() async {
    final gmap = await _gmapReady.future;

    final fixScroll = nofixScroll == null || nofixScroll.toLowerCase() == "false";
    final scroller = getScroller.value;
    final base = getBase.value;
    final curHeight = gmap.hostElement.getBoundingClientRect().height.round();
    final toolbar = (getToolbar == null) ? null : getToolbar.value;

    void scroll(int nextHeight, int move) {
      final scrollTo = scroller.scrollTop + move;

      _logger.info(
          "Animation of map: height: ${curHeight} -> ${nextHeight}, move: ${move}, scrollTo: ${scrollTo}, duration: ${animationDur}");

      moveToolbar(bool hide) {
        final frames = [
          {'height': "${toolbarOriginalHeight}px"},
          {'height': "0"}
        ];
        new CoreAnimation()
          ..target = toolbar
          ..duration = animationDur.inMilliseconds
          ..keyframes = hide ? frames : frames.reversed.toList()
          ..fill = "forwards"
          ..play();
      }
      if (toolbar != null) moveToolbar(curHeight < nextHeight);

      shift(String translation, int duration) => new CoreAnimation()
        ..target = base
        ..duration = duration
        ..fill = "both"
        ..keyframes = [
          {'transform': "none"},
          {'transform': translation}
        ]
        ..play();

      onFinish() {
        if (move != 0) new Future.delayed(new Duration(milliseconds: 10), () {
          shift("none", 0);
          scroller.scrollTop = scrollTo;
        });
        _isChanging = false;
      }
      if (move != 0) {
        shift("translateY(${-move}px)", animationDur.inMilliseconds);
      }

      gmap.zoom = _curZoom;

      new CoreAnimation()
        ..target = gmap.hostElement
        ..duration = animationDur.inMilliseconds
        ..fill = "forwards"
        ..customEffect = (timeFractal, target, animation) {
          final delta = (nextHeight - curHeight) * timeFractal;
          target.style.height = "${curHeight + delta.round()}px";
          gmap.triggerResize();
          gmap.panTo(_curCenter);
          if (timeFractal == 1) onFinish();
        }
        ..play();
    }

    if (isExpanded) {
      _logger.fine("Shrink map: ${gmap}");
      if (fixScroll != null && fixScroll) scroller.style.overflowY = "auto";

      scroll(shrinkedHeightReal, 0);
      isExpanded = false;
      popMe();
    } else {
      _logger.fine("Expand map: ${gmap}");
      if (fixScroll != null && fixScroll) scroller.style.overflowY = "hidden";

      final int scrollTop = scroller.scrollTop;
      final int top = base.getBoundingClientRect().top.round();
      final offset = top + scrollTop;
      _logger.finest("offset: ${offset}(${top} + ${scrollTop})");

      final int curPos = gmap.hostElement.getBoundingClientRect().top.round() - offset;
      _logger.finest("Map host pos: ${curPos}");

      toolbarOriginalHeight = (toolbar == null) ? 0 : toolbar.getBoundingClientRect().height.round();
      if (expandedHeight == null) {
        _logger.finest("Toolbar height: ${toolbarOriginalHeight}");
        _logger.finest("Window height: ${window.innerHeight}");

        expandedHeight = window.innerHeight - offset + toolbarOriginalHeight;
      }
      scroll(expandedHeight, Math.max(0, curPos));
      isExpanded = true;
      pushMe();
    }
  }
}
