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
