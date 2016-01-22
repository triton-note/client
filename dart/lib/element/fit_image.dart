library triton_note.element.fit_image;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_animation.dart';

import 'package:triton_note/util/getter_setter.dart';
import 'package:triton_note/util/geometry.dart';

final _logger = new Logger('FitImageElement');

@Component(
    selector: 'fit-image',
    templateUrl: 'packages/triton_note/element/fit_image.html',
    cssUrl: 'packages/triton_note/element/fit_image.css',
    useShadowDom: true)
class FitImageElement {
  @NgOneWayOneTime('setter') set setter(Setter<FitImageElement> v) => v?.value = this; // Optional
  @NgOneWay('width') int width;
  @NgOneWay('height') int height;
  @NgOneWay('url') String url;
  @NgOneWay('shrink') bool shrink;
  @NgOneWay('changable') bool changable;
  @NgAttr('align') String alignName;

  bool _loaded = false;

  FitImageElement();

  loaded(event) {
    if (changable == null || !changable) {
      if (_loaded) return;
      _loaded = true;
    }

    _logger.fine("Image loaded: ${event.target}");
    final ImageElement target = event.target;

    final real = new Size.fromRect(target.client);
    final base = new Size(width.toDouble(), height.toDouble());
    final fit = real.putInto(base);
    _logger.fine("Real:${real} -> Base:${base} => Fit:${fit}");
    if (real.width == 0 && real.height == 0) {
      _logger.warning(() => "No size: ${real}");
      return;
    }

    if (shrink != null && shrink) {
      target.parent.style
        ..width = "${fit.width.floor()}px"
        ..height = "${fit.height.floor()}px"
        ..background = "transparent";
    } else {
      final align = new Alignment2d.fromName(alignName == null ? "center" : alignName);
      final margin = align.at(base, fit);
      _logger.fine("Fitted margin: ${margin}");
      target.style
        ..marginTop = "${margin.top.floor()}px"
        ..marginBottom = "${margin.bottom.floor()}px"
        ..marginLeft = "${margin.left.floor()}px"
        ..marginRight = "${margin.right.floor()}px";
      new CoreAnimation()
        ..duration = 1000
        ..keyframes = [
          {'background': "#eee"},
          {'background': "transparent"}
        ]
        ..easing = "ease"
        ..fill = "forwards"
        ..target = target.parent
        ..play();
    }

    target
      ..width = fit.width.floor()
      ..height = fit.height.floor();
    new CoreAnimation()
      ..duration = 600
      ..keyframes = [
        {'opacity': 0},
        {'opacity': 1}
      ]
      ..easing = "ease-in-out"
      ..fill = "forwards"
      ..target = target
      ..play();
  }
}
