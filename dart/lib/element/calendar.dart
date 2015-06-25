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
  static const maxPages = 10;
  static const transitionNormal = "slide-from-right";
  static const transitionToday = "cross-fade-all";

  @NgTwoWay('value') DateTime value;

  CoreAnimatedPages _pages;
  DateTime _currentFirst;
  get currentFirst => _currentFirst;
  set currentFirst(DateTime v) => _currentFirst = new DateTime(v.year, v.month);

  void onShadowRoot(ShadowRoot shadowRoot) {
    _pages = shadowRoot.getElementById('calendar-pages');
    currentFirst = new DateTime(value.year, value.month);
    _pages.append(_makePage());
    _pages.selected = 0;
  }

  Element _makePage() {
    print("Creating page: ${currentFirst}");
    final format = new Date();
    final page = document.createElement('section');
    final content = document.createElement('div');
    content.appendHtml("""
<div id="head"><p>${format(currentFirst, 'MMM, yyyy')}</p></div>
""");
    page.append(content);
    return page;
  }

  today() async {
    currentFirst = new DateTime.now();
    print("Today's month: ${currentFirst}");
    _pages.transitions = transitionToday;

    final all = _pages.querySelectorAll('section');
    print("Remove all sections: ${all.length}");
    all.forEach((e) => e.remove());

    _pages.append(_makePage());
    _pages.selected = 0;
  }

  previousMonth() async {
    currentFirst = currentFirst.subtract(new Duration(days: 1));
    print("Previous month: ${currentFirst}");
    _pages.transitions = transitionNormal;

    final index = _pages.selected;
    if (index == 0) {
      final all = _pages.querySelectorAll('section');
      print("sections: ${all.length}");
      if (maxPages < all.length) {
        all.last.remove();
      }

      _pages.insertBefore(_makePage(), all.first);
      _pages.selected = index;
    } else {
      _pages.selected = index - 1;
    }
  }

  nextMonth() async {
    currentFirst = currentFirst.add(new Duration(days: 31));
    print("Next month: ${currentFirst}");
    _pages.transitions = transitionNormal;

    final index = _pages.selected;
    final all = _pages.querySelectorAll('section');
    print("sections: ${all.length}");

    if (index == all.length - 1) {
      _pages.append(_makePage());
    }
    if (maxPages < all.length) {
      all.first.remove();
      _pages.selected = index;
    } else {
      _pages.selected = index + 1;
    }
  }
}
