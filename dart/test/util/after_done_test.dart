library after_done_test;

import 'dart:async';

import 'package:unittest/unittest.dart';

import 'package:triton_note/util/after_done.dart';

main() {
  test('listen', () {
    final result = new Completer();
    final map = {};
    final a = new AfterDone("test listen");
    a.listen((e) {
      map["a"] = e;
      result.complete(e);
    });
    expect(map.length, 0);
    a.done(1);
    return result.future.then((_) {
      expect(map.length, 1);
      expect(map["a"], 1);
    });
  });

  test('listen twice', () {
    final result = new Completer();
    final map = {};
    final a = new AfterDone("test listen twice");
    a.listen((e) {
      map["a"] = e;
      if (map.length == 2) result.complete(true);
    });
    a.listen((e) {
      map["b"] = e;
      if (map.length == 2) result.complete(true);
    });
    expect(map.length, 0);
    a.done(1);
    return result.future.then((_) {
      expect(map.length, 2);
      expect(map["a"], 1);
      expect(map["b"], 1);
    });
  });

  test('listen after done', () async {
    final result = new Completer();
    final map = {};
    final a = new AfterDone("test listen after done");
    a.listen((e) {
      map["a"] = e;
      if (map.length == 2) result.complete(true);
    });
    expect(map.length, 0);
    a.done(1);
    await new Future.delayed(new Duration(seconds: 1), () => true);
    expect(map.length, 1);
    expect(map["a"], 1);
    a.listen((e) {
      map["b"] = e;
      if (map.length == 2) result.complete(true);
    });
    expect(map.length, 2);
    expect(map["b"], 1);
  });
}
