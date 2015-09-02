library triton_note.util.getter_setter;

import 'dart:async';

import 'package:logging/logging.dart';

final _logger = new Logger('getter_setter');

class Getter<T> {
  final Function _getter;

  Getter(T getter()) : this._getter = getter;

  T get value => _getter();
}

class Setter<T> {
  final Function _setter;

  Setter(void setter(T v)) : this._setter = setter;

  void set value(T v) => _setter(v);
}

class GetterSetter<T> implements Getter<T>, Setter<T> {
  final Function _getter;
  final Function _setter;

  GetterSetter(T getter(), void setter(T v))
      : this._getter = getter,
        this._setter = setter;

  T get value => _getter();
  void set value(T v) => _setter(v);
}

class CachedValue<T> implements Getter<T> {
  T _cache;
  final Function _getter;

  CachedValue(T getter()) : this._getter = getter;

  T get value {
    if (_cache == null) _cache = _getter();
    return _cache;
  }

  void clear() => _cache = null;
}

class PipeValue<T> implements GetterSetter<T> {
  T _cache;

  Function _getter;
  Function _setter;

  PipeValue() {
    _getter = () => _cache;
    _setter = (v) => _cache = v;
  }

  T get value => _getter();
  void set value(T v) => _setter(v);
}

class FuturedValue<T> implements Setter<T> {
  Function _setter;
  Completer<T> _completer = new Completer();

  FuturedValue() {
    _setter = ((T v) {
      if (v != null && !_completer.isCompleted) _completer.complete(v);
    });
  }
  factory FuturedValue.wrap(Getter<T> src) {
    final t = new FuturedValue();
    t._setter(src.value);
    return t;
  }

  void set value(T v) => _setter(v);

  void reset() {
    _completer = new Completer();
  }

  Future<T> get future => _completer.future;
}

abstract class StreamedUpdate<T> {
  Stream<T> get onUpdate;
}

class StreamedValue<T> implements Setter<T>, StreamedUpdate<T> {
  Function _setter;
  final StreamController<T> sc = new StreamController();

  StreamedValue() {
    _setter = ((T v) {
      sc.add(v);
    });
  }

  void set value(T v) => _setter(v);

  Stream<T> get onUpdate => sc.stream;
}
