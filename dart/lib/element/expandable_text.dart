library triton_note.element.expandable_text;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_animation.dart';

import 'package:triton_note/util/main_frame.dart';

final _logger = new Logger('ExpandableTextElement');

@Component(
    selector: 'expandable-text',
    templateUrl: 'packages/triton_note/element/expandable_text.html',
    cssUrl: 'packages/triton_note/element/expandable_text.css',
    useShadowDom: true)
class ExpandableTextElement extends ShadowRootAware {
  @NgOneWay('text') String text;
  @NgOneWay('shrinked-lines') int shrinkedLines;
  @NgOneWay('expanded-lines') int expandedLines; // Optional (default: full text)

  ShadowRoot _root;
  Element textarea;
  int shrinkedHeight, expandedHeight;
  bool hasMore = false;
  bool isExpanded = false;

  @override
  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
    _initialize();
  }

  _initialize() async {
    textarea = _root.querySelector('#text :first-child');

    Future<int> getHeight(int lines) async {
      _setLines(lines);
      return new Future.delayed(new Duration(milliseconds: 10), () {
        return textarea.getBoundingClientRect().height.round();
      });
    }
    expandedHeight = await getHeight(expandedLines);
    shrinkedHeight = await getHeight(shrinkedLines);
    hasMore = shrinkedHeight < expandedHeight;

    _logger.fine("Obtained height: shrinked=${shrinkedHeight}, expanded=${expandedHeight}");
    textarea.style.opacity = "1";
  }

  _setLines(int v) {
    _logger.fine("Set line clamp: '${v}'");
    if (v != null) {
      textarea.style.setProperty('-webkit-line-clamp', v.toString());
    } else {
      textarea.style.removeProperty('-webkit-line-clamp');
    }
  }

  toggle() => alfterRippling(() async {
    final list = [{'height': "${shrinkedHeight}px"}, {'height': "${expandedHeight}px"}];
    final frames = isExpanded ? list.reversed.toList() : list;

    _logger.fine("Toggle text expand: ${isExpanded}: ${frames}");

    new CoreAnimation()
      ..target = textarea
      ..duration = 300
      ..fill = "both"
      ..keyframes = frames
      ..play();
    _setLines(isExpanded ? shrinkedLines : expandedLines);

    isExpanded = !isExpanded;
  });
}
