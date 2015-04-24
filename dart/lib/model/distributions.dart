library distributions;

import 'package:triton_note/model/_json_support.dart';
import 'package:triton_note/model/location.dart';

abstract class Catch implements JsonSupport {
  String reportId;
  String name;
  int count;
  DateTime date;
  GeoInfo geoinfo;

  factory Catch.fromJsonString(String text) => new _CatchImpl(JSON.decode(text));
  factory Catch.fromMap(Map data) => new _CatchImpl(data);
}

class _CatchImpl implements Catch {
  final Map _data;
  final CachedProp<DateTime> _date;
  final CachedProp<GeoInfo> _geoinfo;

  _CatchImpl(Map data)
      : _data = data,
        _date = new CachedProp<DateTime>(
            data, 'geoinfo', (int v) => new DateTime.fromMillisecondsSinceEpoch(v), (v) => v.millisecondsSinceEpoch),
        _geoinfo = new CachedProp<GeoInfo>(data, 'geoinfo', (map) => new GeoInfo.fromMap(map));

  Map toMap() => _data;

  String get reportId => _data['reportId'];
  set reportId(String v) => _data['reportId'] = v;

  String get name => _data['name'];
  set name(String v) => _data['name'] = v;

  int get count => _data['count'];
  set count(int v) => _data['count'] = v;

  DateTime get date => _date.value;
  set date(DateTime v) => _date.value = v;

  GeoInfo get geoinfo => _geoinfo.value;
  set geoinfo(GeoInfo v) => _geoinfo.value = v;
}

abstract class NameCount implements JsonSupport {
  String name;
  int count;

  factory NameCount.fromJsonString(String text) => new _NameCountImpl(JSON.decode(text));
  factory NameCount.fromMap(Map data) => new _NameCountImpl(data);
}

class _NameCountImpl implements NameCount {
  final Map _data;
  _NameCountImpl(this._data);
  Map toMap() => _data;

  String get name => _data['name'];
  set name(String v) => _data['name'] = v;

  int get count => _data['count'];
  set count(int v) => _data['count'] = v;
}
