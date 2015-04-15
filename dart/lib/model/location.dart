library location;

import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/util/enums.dart';
import 'package:triton_note/util/json_support.dart';

abstract class Location implements JsonSupport {
  String name;
  GeoInfo geoinfo;

  factory Location.fromJsonString(String text) => new _LocationImpl(JSON.decode(text));
  factory Location.fromMap(Map data) => new _LocationImpl(data);
}

class _LocationImpl implements Location {
  Map _data;
  _LocationImpl(this._data);
  Map toMap() => new Map.from(_data);

  String get name => _data['name'];
  set name(String v) => _data['name'] = v;

  GeoInfo get geoinfo => (_data['geoinfo'] == null) ? null : new GeoInfo.fromMap(_data['geoinfo']);
  set geoinfo(GeoInfo v) => _data['geoinfo'] = v.toMap();
}

abstract class GeoInfo implements JsonSupport {
  double latitude;
  double longitude;

  factory GeoInfo.fromJsonString(String text) => new _GeoInfoImpl(JSON.decode(text));
  factory GeoInfo.fromMap(Map data) => new _GeoInfoImpl(data);
}

class _GeoInfoImpl implements GeoInfo {
  Map _data;
  _GeoInfoImpl(this._data);
  Map toMap() => new Map.from(_data);

  double get latitude => _data['latitude'];
  set latitude(double v) => _data['latitude'] = v;

  double get longitude => _data['longitude'];
  set longitude(double v) => _data['longitude'] = v;
}

abstract class Condition implements JsonSupport {
  int moon;
  Tide tide;
  Weather weather;

  factory Condition.fromJsonString(String text) => new _ConditionImpl(JSON.decode(text));
  factory Condition.fromMap(Map data) => new _ConditionImpl(data);
}

class _ConditionImpl implements Condition {
  Map _data;
  _ConditionImpl(this._data);
  Map toMap() => new Map.from(_data);

  int get moon => _data['moon'];
  set moon(int v) => _data['moon'] = v;

  Tide get tide => (_data['tide'] == null) ? null : enumByName(Tide.values, _data['tide']);
  set tide(Tide v) => _data['tide'] = nameOfEnum(v);

  Weather get weather => (_data['weather'] == null) ? null : new Weather.fromMap(_data['weather']);
  set weather(Weather v) => _data['weather'] = v.toMap();
}

enum Tide { Flood, High, Ebb, Low }

abstract class Weather implements JsonSupport {
  String nominal;
  String iconUrl;
  Temperature temperature;

  factory Weather.fromJsonString(String text) => new _WeatherImpl(JSON.decode(text));
  factory Weather.fromMap(Map data) => new _WeatherImpl(data);
}

class _WeatherImpl implements Weather {
  Map _data;
  _WeatherImpl(this._data);
  Map toMap() => new Map.from(_data);

  String get nominal => _data['nominal'];
  set nominal(String v) => _data['nominal'] = v;

  String get iconUrl => _data['iconUrl'];
  set iconUrl(String v) => _data['iconUrl'] = v;

  Temperature get temperature => (_data['temperature'] == null) ? null : new Temperature.fromMap(_data['temperature']);
  set temperature(Temperature v) => _data['temperature'] = v.toMap();
}
