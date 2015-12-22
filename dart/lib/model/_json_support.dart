library triton_note.model.json_support;

import 'dart:async';
import 'dart:convert';
export 'dart:convert';

import 'package:logging/logging.dart';

import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/util/getter_setter.dart';

final _logger = new Logger('CachedProp');

abstract class JsonSupport {
  Map get asMap;

  @override
  String toString() => JSON.encode(asMap);
}

typedef T _Decoder<T>(data);
typedef _Encoder<T>(T obj);

class CachedProp<T> {
  final Map _data;
  final String name;
  final _Decoder<T> _decode;
  final _Encoder<T> _encode;
  T _cache;

  CachedProp(this._data, this.name, this._decode, this._encode);

  factory CachedProp.forMap(Map data, String name, _Decoder<T> decoder) =>
      new CachedProp(data, name, decoder, (JsonSupport obj) => obj == null ? null : obj.asMap);

  factory CachedProp.forValueUnit(Map data, String name, T decoder(num value)) =>
      new CachedProp(data, name, decoder, (ValueUnit obj) => obj == null ? null : obj.asStandard().value);

  StreamSubscription<T> _currentListener;
  T _listen(T a) {
    _currentListener?.cancel();
    if (a != null && a is StreamedUpdate<T>) {
      _logger.finest(() => "Listen update [#${a.hashCode}] ${a}");
      _currentListener = (a as StreamedUpdate<T>).onUpdate.listen(_update);
    }
    return a;
  }

  T _update(T a) => _data[name] = _encode(_cache = a);

  T get value {
    if (_cache != null) return _cache;
    final pre = _data[name];
    return _cache = _listen(pre == null ? null : _decode(pre));
  }

  set value(T v) => _update(_listen(v));
}
