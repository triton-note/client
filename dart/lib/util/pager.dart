library triton_note.util.pager;

import 'dart:async';

import 'package:logging/logging.dart';

final _logger = new Logger('Pager');

abstract class Pager<T> {
  bool get hasMore;
  Future<List<T>> more(int pageSize);
  void reset();
}

class PagingList<T> implements Pager<T> {
  final Pager<T> _pager;
  final List<T> list = [];

  PagingList(this._pager);

  bool get hasMore => _pager.hasMore;

  void reset() {
    _pager.reset();
    list.clear();
  }

  Future<List<T>> more(int pageSize) async {
    final a = await _pager.more(pageSize);
    list.addAll(a);
    return a;
  }
}
