library triton_note.util.getter_setter;

import 'package:logging/logging.dart';

final _logger = new Logger('getter_setter');

class Getter<T> {
  final Function _getter;

  Getter(this._getter);

  T get value => _getter();
}

class Setter<T> {
  final Function _setter;

  Setter(this._setter);

  void set value(T v) => _setter(v);
}

class GetterSetter<T> implements Getter<T>, Setter<T> {
  final Function _getter;
  final Function _setter;

  GetterSetter(this._getter, this._setter);

  T get value => _getter();
  void set value(T v) => _setter(v);
}

class CachedValue<T> implements Getter<T> {
  T _cache;
  final Function _getter;

  CachedValue(this._getter);

  T get value {
    if (_cache == null) _cache = _getter();
    return _cache;
  }
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
