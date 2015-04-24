library json_support;

export 'dart:convert';

abstract class JsonSupport {
  Map toMap();
}

typedef T _Decoder<T>(data);
typedef _Encoder<T>(T obj);

class CachedProp<T> {
  final _data;
  final _name;
  final _Decoder<T> _decode;
  final _Encoder<T> _encode;
  T _cache;

  CachedProp(this._data, this._name, this._decode, [_Encoder<T> encode = null])
      : this._encode = (encode != null) ? encode : ((T o) => (o as JsonSupport).toMap());

  T get value => (_cache != null) ? _cache : (_data[_name] == null) ? null : _cache = _decode(_data[_name]);
  set value(T v) => _data[_name] = _encode(_cache = v);
}
