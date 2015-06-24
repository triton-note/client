library triton_note.element.calendar;

import 'dart:html';
import 'package:angular/angular.dart';
import 'package:core_elements/core_animated_pages.dart';

@Component(
    selector: 'calendar',
    templateUrl: 'packages/triton_note/element/calendar.html',
    cssUrl: 'packages/triton_note/element/calendar.css',
    useShadowDom: true)
class CalendarElement extends ShadowRootAware {
  @NgTwoWay('value') DateTime value;

  CoreAnimatedPages _pages;
  int _currentMonth;

  void onShadowRoot(ShadowRoot shadowRoot) {
    _pages = shadowRoot.getElementById('calendar-pages');
    _currentMonth = value.month;
    _makePage(_currentMonth);
    _pages.selected = 0;
  }

  _makePage(int month) {
    final page = document.createElement('section');
    final content = document.createElement('paper-shadow');
    content.appendHtml("""
<div><p>${month}</p></div>
""");
    page.append(content);
    _pages.append(page);
  }

  previousMonth() {}

  nextMonth() {}
}
