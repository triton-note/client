library location;

import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/util/enums.dart';
import 'package:triton_note/model/_json_support.dart';

abstract class Location implements JsonSupport {
  String name;
  GeoInfo geoinfo;

  factory Location.fromMap(Map data) => new _LocationImpl(data);
}

class _LocationImpl extends JsonSupport implements Location {
  final Map _data;
  final CachedProp<GeoInfo> _geoinfo;

  _LocationImpl(Map data)
      : _data = data,
        _geoinfo = new CachedProp<GeoInfo>(data, 'geoinfo', (map) => new GeoInfo.fromMap(map));

  Map get asMap => _data;

  String get name => _data['name'];
  set name(String v) => _data['name'] = v;

  GeoInfo get geoinfo => _geoinfo.value;
  set geoinfo(GeoInfo v) => _geoinfo.value = v;
}

abstract class GeoInfo implements JsonSupport {
  double latitude;
  double longitude;

  factory GeoInfo.fromMap(Map data) => new _GeoInfoImpl(data);
}

class _GeoInfoImpl extends JsonSupport implements GeoInfo {
  final Map _data;
  _GeoInfoImpl(this._data);
  Map get asMap => _data;

  double get latitude => _data['latitude'].toDouble();
  set latitude(double v) => _data['latitude'] = v;

  double get longitude => _data['longitude'].toDouble();
  set longitude(double v) => _data['longitude'] = v;
}

abstract class Condition implements JsonSupport {
  int moon;
  Tide tide;
  Weather weather;

  factory Condition.fromMap(Map data) => new _ConditionImpl(data);
}

class _ConditionImpl extends JsonSupport implements Condition {
  final Map _data;
  final CachedProp<Tide> _tide;
  final CachedProp<Weather> _weather;

  _ConditionImpl(Map data)
      : _data = data,
        _tide = new CachedProp<Tide>(data, 'tide', (o) => enumByName(Tide.values, o), (v) => nameOfEnum(v)),
        _weather = new CachedProp<Weather>(data, 'weather', (map) => new Weather.fromMap(map));

  Map get asMap => _data;

  int get moon => _data['moon'];
  set moon(int v) => _data['moon'] = v;

  Tide get tide => _tide.value;
  set tide(Tide v) => _tide.value = v;

  Weather get weather => _weather.value;
  set weather(Weather v) => _weather.value = v;
}

enum Tide { Flood, High, Ebb, Low }

abstract class Weather implements JsonSupport {
  String nominal;
  String iconUrl;
  Temperature temperature;

  factory Weather.fromMap(Map data) => new _WeatherImpl(data);
}

class _WeatherImpl extends JsonSupport implements Weather {
  final Map _data;
  final CachedProp<Temperature> _temperature;

  _WeatherImpl(Map data)
      : _data = data,
        _temperature = new CachedProp<Temperature>(data, 'temperature', (map) => new Temperature.fromMap(map));

  Map get asMap => _data;

  String get nominal => _data['nominal'];
  set nominal(String v) => _data['nominal'] = v;

  String get iconUrl => _data['iconUrl'];
  set iconUrl(String v) => _data['iconUrl'] = v;

  Temperature get temperature => (_data['temperature'] == null) ? null : new Temperature.fromMap(_data['temperature']);
  set temperature(Temperature v) => _data['temperature'] = v.asMap;
}
