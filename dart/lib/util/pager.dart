library triton_note.util.pager;

import 'dart:async';

import 'package:logging/logging.dart';

final _logger = new Logger('Pager');

abstract class Pager<T> {
  bool get hasMore;
  Future<List<T>> more(int pageSize);
  void reset();
}
