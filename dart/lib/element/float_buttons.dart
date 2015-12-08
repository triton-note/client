library triton_note.element.float_buttons;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_animation.dart';

final _logger = new Logger('FloatButtonsElement');

@Component(
    selector: 'float-buttons',
    templateUrl: 'packages/triton_note/element/float_buttons.html',
    cssUrl: 'packages/triton_note/element/float_buttons.css',
    useShadowDom: true)
class FloatButtonsElement extends ShadowRootAware {
  @NgOneWay('duration') String duration;
  Duration get _duration => new Duration(seconds: int.parse(duration ?? "5"));

  Element _floater;

  @override
  void onShadowRoot(ShadowRoot sr) {
    _floater = sr.querySelector('div#float_buttons');
    sr.host.children.toList().forEach(_floater.append);

    _logger.info(() => "Host: ${sr.host}, Parent: ${sr.parent}");
    sr.host.parent.onClick.listen((event) => _showButtons());
    _startTimer();
  }

  Timer _buttonsTimer;
  bool _buttonsShow;

  _startTimer() {
    if (_buttonsTimer != null) _buttonsTimer.cancel();
    _buttonsTimer = new Timer(_duration, _hideButtons);
  }

  _showButtons() {
    _logger.fine("show float buttons");
    _startTimer();
    if (!_buttonsShow) _animateButtons(true);
  }

  _hideButtons() {
    _logger.fine("hide float buttons");
    _animateButtons(false);
  }

  _animateButtons(bool show) {
    _buttonsShow = show;
    final move = _floater.clientHeight;
    final list = [
      {'transform': "translateY(${-move}px)"},
      {'transform': "none"}
    ];
    final frames = show ? list : list.reversed.toList();

    new CoreAnimation()
      ..target = _floater
      ..duration = 300
      ..fill = "forwards"
      ..keyframes = frames
      ..play();
  }
}
