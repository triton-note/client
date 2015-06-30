library triton_note.element.about_oclock;

import 'package:angular/angular.dart';

@Component(
    selector: 'num-input',
    templateUrl: 'packages/triton_note/element/num_input.html',
    cssUrl: 'packages/triton_note/element/num_input.css',
    useShadowDom: true)
class NumInputElement {
  @NgTwoWay('value') int value;
  @NgAttr('size') String size;
  @NgAttr('max') String max;
  @NgAttr('min') String min;

  int get fontSize => size == null ? 20 : int.parse(size);
  int get minValue => min == null ? null : int.parse(min);
  int get maxValue => max == null ? null : int.parse(max);

  _loop(int v) {
    final loop = (maxValue - minValue + 1);
    return (v + loop) % loop + minValue;
  }

  _limit(int v) {
    if (maxValue != null && minValue != null) return _loop(v);
    if (minValue != null && v < minValue) return minValue;
    if (maxValue != null && maxValue < v) return maxValue;
    return v;
  }

  up() {
    value = _limit(value + 1);
  }
  down() {
    value = _limit(value - 1);
  }
}
