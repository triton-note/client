library triton_note.element.calendar;

import 'dart:html';
import 'package:angular/angular.dart';
import 'package:core_elements/core_animated_pages.dart';

@Component(
    selector: 'calendar',
    templateUrl: 'packages/triton_note/element/calendar.html',
    cssUrl: 'packages/triton_note/element/calendar.css',
    useShadowDom: true)
class CalendarElement extends ShadowRootAware with AttachAware {
  static const maxPages = 10;
  static const transitionNormal = "slide-from-right";
  static const transitionToday = "cross-fade-all";
  static const weekNames = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sut'];
  static const day1 = const Duration(days: 1);
  static const day31 = const Duration(days: 31);

  @NgTwoWay('value') DateTime value;
  @NgAttr('start-of-week') int startOfWeek;

  @override
  void attach() {
    startOfWeek = startOfWeek == null ? 0 : startOfWeek;
    value = new DateTime(value.year, value.month, value.day);
    pageA_currentFirst = new DateTime(value.year, value.month);

    weekNamesList = [];
    for (var i = 0; i < 7; i++) {
      weekNamesList.add(weekNames[(startOfWeek + i) % 7]);
    }
  }
  @override
  void onShadowRoot(ShadowRoot shadowRoot) {
    _pages = shadowRoot.getElementsByTagName('core-animated-pages')[0] as CoreAnimatedPages
      ..transitions = transitionNormal
      ..selected = 0;
  }

  List<String> weekNamesList;
  CoreAnimatedPages _pages;
  DateTime _pageA_currentFirst, _pageB_currentFirst;
  List<List<DateTime>> pageA_weeks, pageB_weeks;
  DateTime today;

  DateTime get pageA_currentFirst => _pageA_currentFirst;
  set pageA_currentFirst(DateTime v) {
    pageA_weeks = weeks(v);
    _pageA_currentFirst = v;
  }
  DateTime get pageB_currentFirst => _pageB_currentFirst;
  set pageB_currentFirst(DateTime v) {
    pageB_weeks = weeks(v);
    _pageB_currentFirst = v;
  }

  List<List<DateTime>> weeks(DateTime currentFirst) {
    print("Creating calender: ${currentFirst}");
    today = makeToday();

    final last = atFirst(currentFirst.add(day31));
    var day = new DateTime(currentFirst.year, currentFirst.month, 1);
    day = day.subtract(new Duration(days: (day.weekday - startOfWeek + 7) % 7));
    print("Start from: ${day} to ${last}");

    final table = [];
    while (day.isBefore(last)) {
      print("week at ${day}");
      final row = [];
      for (var i = 0; i < 7; i++) {
        final list = [day.month == currentFirst.month ? "inside" : "outside"];
        if (day == value) list.add('selected');
        if (day == today) list.add('today');

        row.add(day);
        day = day.add(day1);
      }
      table.add(row);
    }
    return table;
  }

  DateTime atFirst(DateTime v) => new DateTime(v.year, v.month);
  DateTime makeToday() {
    final now = new DateTime.now();
    return new DateTime(now.year, now.month, now.day);
  }

  selectDay(int year, int month, int day) {
    final selected = new DateTime(year, month, day);
    print("Selected: ${selected}");
    value = selected;
  }

  goToday() async {
    _pages.transitions = transitionToday;

    final cur = atFirst(new DateTime.now());
    print("Today's month: ${cur}");

    final all = _pages.querySelectorAll('section');
    final index = _pages.selected;

    if (all[index].id == "pageA") {
      pageB_currentFirst = cur;
    } else {
      pageA_currentFirst = cur;
    }
    _pages.selected = (index + 1) % 2;
  }

  previousMonth() async {
    _pages.transitions = transitionNormal;

    final index = _pages.selected;
    final all = _pages.querySelectorAll('section');

    if (all[index].id == "pageA") {
      pageB_currentFirst = atFirst(pageA_currentFirst.subtract(day1));
    } else {
      pageA_currentFirst = atFirst(pageB_currentFirst.subtract(day1));
    }
    if (index == 0) {
      final pre = all[1];
      pre.remove();
      _pages.insertBefore(pre, all[0]);
    }
    _pages.selected = 0;
  }

  nextMonth() async {
    _pages.transitions = transitionNormal;

    final index = _pages.selected;
    final all = _pages.querySelectorAll('section');

    if (all[index].id == "pageA") {
      pageB_currentFirst = atFirst(pageA_currentFirst.add(day31));
    } else {
      pageA_currentFirst = atFirst(pageB_currentFirst.add(day31));
    }
    if (index == 1) {
      final next = all[0];
      next.remove();
      _pages.append(next);
    }
    _pages.selected = 1;
  }
}
