library triton_note.util.pager;

import 'dart:async';
import 'dart:collection';

import 'package:logging/logging.dart';

final _logger = new Logger('Pager');

abstract class Pager<T> {
  bool get hasMore;
  Future<List<T>> more(int pageSize);
  void reset();
}

class InfiniteList<T> implements Pager<T> {
  final Pager<T> _pager;
  final List<T> _list = [];
  UnmodifiableListView<T> _view;

  InfiniteList(this._pager);

  List<T> get list => _view;

  bool get hasMore => _pager.hasMore;

  void reset() {
    _pager.reset();
    _list.clear();
    _view = new UnmodifiableListView(_list);
  }

  Future<List<T>> more(int pageSize) async {
    final a = await _pager.more(pageSize);
    _list.addAll(a);
    _view = new UnmodifiableListView(_list);
    return a;
  }
}
