library triton_note.element.expandable_gmap;

import 'dart:async';
import 'dart:html';
import 'dart:math' as Math;

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_animation.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/main_frame.dart';
import 'package:triton_note/service/googlemaps_browser.dart';

final _logger = new Logger('ExpandableGMapElement');

@Component(
    selector: 'expandable-gmap',
    templateUrl: 'packages/triton_note/element/expandable_gmap.html',
    cssUrl: 'packages/triton_note/element/expandable_gmap.css',
    useShadowDom: true)
class ExpandableGMapElement extends ShadowRootAware {
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

  Completer<GoogleMap> _readyGMap;
  bool get isReady {
    if (_root != null && _readyGMap == null) {
      final div = _root.querySelector('#google-maps');
      if (shrinkedHeightReal == null) {
        final w = div.clientWidth;
        _logger.finest("Checking width of host div: ${w}");
        if (w > 0) {
          shrinkedHeightReal = (shrinkedHeight != null) ? shrinkedHeight : (w * 2 / (1 + Math.sqrt(5))).round();
          _logger.fine("Shrinked height: ${shrinkedHeightReal}");
          div.style.height = "${shrinkedHeightReal}px";
        }
      }
      if (center != null && shrinkedHeightReal != null) {
        _readyGMap = new Completer();
        makeGoogleMap(div, center).then((v) {
          _readyGMap.complete(v);
          if (setGMap != null) setGMap.value = v;
        });
      }
    }
    return _readyGMap != null && _readyGMap.isCompleted;
  }

  @override
  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
  }

  toggle() => alfterRippling(() {
    _root.host.dispatchEvent(new Event(isExpanded ? 'shrinking' : 'expanding'));
    _toggle();
  });

  _toggle() async {
    final gmap = await _readyGMap.future;
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
        final frames = [{'height': "${toolbarOriginalHeight}px"}, {'height': "0"}];
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
        ..keyframes = [{'transform': "none"}, {'transform': translation}]
        ..play();

      onFinish() {
        if (move != 0) new Future.delayed(new Duration(milliseconds: 10), () {
          shift("none", 0);
          scroller.scrollTop = scrollTo;
        });
      }
      if (move != 0) {
        shift("translateY(${-move}px)", animationDur.inMilliseconds);
      }
      new CoreAnimation()
        ..target = gmap.hostElement
        ..duration = animationDur.inMilliseconds
        ..fill = "forwards"
        ..customEffect = (timeFractal, target, animation) {
          final delta = (nextHeight - curHeight) * timeFractal;
          target.style.height = "${curHeight + delta.round()}px";
          gmap.triggerResize();
          gmap.panTo(center);
          if (timeFractal == 1) onFinish();
        }
        ..play();
    }

    if (isExpanded) {
      _logger.fine("Shrink map: ${gmap}");
      if (fixScroll != null && fixScroll) scroller.style.overflowY = "auto";

      scroll(shrinkedHeightReal, 0);
      isExpanded = false;
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
        final button = _root.querySelector('#toggle');
        final int buttonHeight =
            (button.getBoundingClientRect().bottom - gmap.hostElement.getBoundingClientRect().bottom).round();

        _logger.finest("Toolbar height: ${toolbarOriginalHeight}");
        _logger.finest("Window height: ${window.innerHeight}");
        _logger.finest("Toggle area: ${button}:${buttonHeight}");

        expandedHeight = window.innerHeight - offset - buttonHeight + toolbarOriginalHeight;
      }
      scroll(expandedHeight, Math.max(0, curPos));
      isExpanded = true;
    }
  }
}
