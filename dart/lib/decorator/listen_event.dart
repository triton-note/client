library listen_event;

import 'dart:html';
import 'package:angular/angular.dart';

@Decorator(selector: '[listen-change-value]')
class ListenChangeValue {
  @NgOneWayOneTime('listen-change-value')
  var callback;

  final Element parent;

  ListenChangeValue(this.parent) {
    parent.addEventListener('change', (event) {
      callback(event.target.value);
    });
  }
}
