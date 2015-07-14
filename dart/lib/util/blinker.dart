library triton_note.util.blinker;

import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:core_elements/core_animation.dart';

import 'package:triton_note/util/getter_setter.dart';

final _logger = new Logger('ReportDetailPage');

class Blinker {
  final Duration blinkDuration, blinkStopDuration;
  final List<BlinkTarget> targets;

  Timer _blinkTimer;
  List<CoreAnimation> _animations;

  Blinker(this.blinkDuration, this.blinkStopDuration, this.targets);

  _blinkAnimate(Element target, Duration duration, List frames) {
    _logger.finest("Blink: ${target}: ${frames}");
    return new CoreAnimation()
      ..target = target
      ..duration = duration.inMilliseconds
      ..keyframes = frames
      ..fill = "forwards"
      ..easing = "ease-in-out"
      ..play();
  }

  _blink(final bool updown) {
    _animations = [];
    List frame(List src) => updown ? src : src.reversed.toList();
    targets.forEach((target) {
      target.asList.forEach((element) {
        _animations.add(_blinkAnimate(element, blinkDuration, frame(target._normalFrames)));
      });
    });
    _blinkTimer = new Timer(blinkDuration, () => _blink(!updown));
  }

  start() {
    _logger.finest("Start blinking...");
    _blink(true);
  }

  stop() {
    _logger.finest("Stop blinking...");
    if (_blinkTimer != null && _blinkTimer.isActive) _blinkTimer.cancel();
    if (_animations != null) _animations.forEach((a) => a.cancel());
    targets.forEach((target) {
      target.asList.forEach((element) {
        _blinkAnimate(element, blinkStopDuration, target._stopFrames);
      });
    });
  }
}

class BlinkTarget {
  final Getter<List<Element>> _getter;
  final List<Map> _normalFrames, _stopFrames;

  BlinkTarget(this._getter, List frames, [List downFrames = null])
      : this._normalFrames = frames.toList(growable: false),
        this._stopFrames = downFrames != null ? downFrames : frames.reversed.toList(growable: false);

  List<Element> get asList => _getter.value;
}
