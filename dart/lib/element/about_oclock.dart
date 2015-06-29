library triton_note.element.about_oclock;

import 'package:angular/angular.dart';

@Component(
    selector: 'about-oclock',
    templateUrl: 'packages/triton_note/element/about_oclock.html',
    cssUrl: 'packages/triton_note/element/about_oclock.css',
    useShadowDom: true)
class AboutOclockElement {
  @NgTwoWay('value') int value;

  up() {
    value = (value + 1) % 24;
  }
  down() {
    value = (value - 1 + 24) % 24;
  }
}
