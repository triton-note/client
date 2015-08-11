library triton_note.model.json_support;

import 'dart:convert';
export 'dart:convert';

abstract class JsonSupport {
  Map get asMap;
  String get asParam => Uri.encodeQueryComponent(JSON.encode(asMap));
  set asParam(String text) => asMap.addAll(JSON.decode(Uri.decodeQueryComponent(text)));

  @override
  String toString() => JSON.encode(asMap);
}

typedef T _Decoder<T>(data);
typedef _Encoder<T>(T obj);

class CachedProp<T> {
  static defaultEncoder(o) => o == null ? null : (o as JsonSupport).asMap;

  final _data;
  final _name;
  final _Decoder<T> _decode;
  final _Encoder<T> _encode;
  T _cache;

  CachedProp(this._data, this._name, this._decode, [_Encoder<T> encode = null])
      : this._encode = (encode != null) ? encode : defaultEncoder;

  T get value => (_cache != null) ? _cache : (_data[_name] == null) ? null : _cache = _decode(_data[_name]);
  set value(T v) => _data[_name] = _encode(_cache = v);
}
