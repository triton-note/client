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
  @NgOneWay('shrinked-height') int shrinkedHeight; // Optional (default: golden ratio of width)
  @NgOneWay('expanded-height') int expandedHeight; // Optional (default: max of base height)
  @NgOneWay('set-gmap') Setter<GoogleMap> setGMap; // Optional (no callback if null)
  @NgOneWay('get-scroller') Getter<Element> getScroller;
  @NgOneWay('get-base') Getter<Element> getBase;
  @NgOneWay('center') GeoInfo center;

  ShadowRoot _root;
  bool isExpanded = false;

  Completer<GoogleMap> _readyGMap;
  bool get isReady {
    if (_root != null && center != null && _readyGMap == null) {
      _readyGMap = new Completer();

      final div = _root.querySelector('#google-maps');
      final w = div.clientWidth;
      _logger.finest("Checking width of host div: ${w}");
      if (w > 0) {
        if (shrinkedHeight == null) shrinkedHeight = (w * 2 / (1 + Math.sqrt(5))).round();
        _logger.fine("Shrinked height: ${shrinkedHeight}");
        div.style.height = "${shrinkedHeight}px";

        makeGoogleMap(div, center).then((v) {
          _readyGMap.complete(v);
          _logger.finest("Callback gmap: ${setGMap}");
          if (setGMap != null) setGMap.value = v;
        });
      } else {
        _readyGMap = null;
      }
    }
    return _readyGMap != null && _readyGMap.isCompleted;
  }

  @override
  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
  }

  toggle() {
    alfterRippling(() async {
      final gmap = await _readyGMap.future;
      if (gmap == null) return;

      final scroller = getScroller.value;
      final base = getBase.value;
      final int curHeight = gmap.hostElement.getBoundingClientRect().height.round();

      scroll(int nextHeight, int move, [int duration = 300]) {
        _logger.info("Animation of map: height: ${curHeight} -> ${nextHeight}, move: ${move}, duration: ${duration}");
        new CoreAnimation()
          ..target = gmap.hostElement
          ..duration = duration
          ..fill = "forwards"
          ..keyframes = [{'height': "${curHeight}px"}, {'height': "${nextHeight}px"}]
          ..play();

        shift(String translation, int duration) => new CoreAnimation()
          ..target = base
          ..duration = duration
          ..fill = "both"
          ..keyframes = [{'transform': "none"}, {'transform': translation}]
          ..play();
        shift("translateY(${-move}px)", duration);

        new Future.delayed(new Duration(milliseconds: (duration * 1.1).round()), () {
          gmap.triggerResize();
          if (move != 0) {
            _logger.finest("Scrolling by ${move}");
            shift("none", 0);
            scroller.scrollTop += move;
          }
        });
      }

      if (isExpanded) {
        _logger.fine("Shrink map: ${gmap}");
        scroll(shrinkedHeight, 0);
        isExpanded = false;
      } else {
        _logger.fine("Expand map: ${gmap}");
        final int scrollTop = scroller.scrollTop;
        final int top = base.getBoundingClientRect().top.round();
        final offset = top + scrollTop;
        _logger.finest("offset: ${offset}(${top} + ${scrollTop})");

        final int curPos = gmap.hostElement.getBoundingClientRect().top.round() - offset;
        _logger.finest("Map host pos: ${curPos}");

        if (expandedHeight == null) {
          final button = _root.querySelector('#toggle');
          final int buttonHeight =
              (button.getBoundingClientRect().bottom - gmap.hostElement.getBoundingClientRect().bottom).round();

          _logger.finest("Window height: ${window.innerHeight}");
          _logger.finest("Toggle area: ${button}:${buttonHeight}");

          expandedHeight = window.innerHeight - offset - buttonHeight;
        }
        scroll(expandedHeight, Math.max(0, curPos));
        isExpanded = true;
      }
    });
  }
}
