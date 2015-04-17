library distributions;

import 'package:triton_note/model/location.dart';
import 'package:triton_note/util/json_support.dart';

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
  Map _data;
  _CatchImpl(this._data);
  Map toMap() => new Map.from(_data);

  String get reportId => _data['reportId'];
  set reportId(String v) => _data['reportId'] = v;

  String get name => _data['name'];
  set name(String v) => _data['name'] = v;

  int get count => _data['count'];
  set count(int v) => _data['count'] = v;

  DateTime get date => (_data['date'] == null) ? null : new DateTime.fromMillisecondsSinceEpoch(_data['date']);
  set date(DateTime v) => _data['date'] = v.millisecondsSinceEpoch;

  GeoInfo get geoinfo => (_data['geoinfo'] == null) ? null : new GeoInfo.fromMap(_data['geoinfo']);
  set geoinfo(GeoInfo v) => _data['geoinfo'] = v.toMap();
}

abstract class NameCount implements JsonSupport {
  String name;
  int count;

  factory NameCount.fromJsonString(String text) => new _NameCountImpl(JSON.decode(text));
  factory NameCount.fromMap(Map data) => new _NameCountImpl(data);
}

class _NameCountImpl implements NameCount {
  Map _data;
  _NameCountImpl(this._data);
  Map toMap() => new Map.from(_data);

  String get name => _data['name'];
  set name(String v) => _data['name'] = v;

  int get count => _data['count'];
  set count(int v) => _data['count'] = v;
}
