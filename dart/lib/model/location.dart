library triton_note.model.location;

import 'dart:math';

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
        _geoinfo = new CachedProp<GeoInfo>.forMap(data, 'geoinfo', (map) => new GeoInfo.fromMap(map));

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

  double distance(GeoInfo other);
}

class _GeoInfoImpl extends JsonSupport implements GeoInfo {
  final Map _data;
  _GeoInfoImpl(this._data);
  Map get asMap => _data;

  double get latitude => _data['latitude'];
  set latitude(double v) => _data['latitude'] = v;

  double get longitude => _data['longitude'];
  set longitude(double v) => _data['longitude'] = v;

  static _toRadian(double v) => v * 2 * PI / 360;
  static const radiusEq = 6378137.000;
  static const radiusPl = 6356752.314;
  static final radiusEq2 = pow(radiusEq, 2);
  static final radiusPl2 = pow(radiusPl, 2);
  static final ecc2 = (radiusEq2 - radiusPl2) / radiusEq2;
  static final rM = radiusEq * (1 - ecc2);

  double distance(GeoInfo other) {
    final srcLat = _toRadian(latitude);
    final srcLng = _toRadian(longitude);
    final dstLat = _toRadian(other.latitude);
    final dstLng = _toRadian(other.longitude);

    final mLat = (srcLat + dstLat) / 2;
    final W = sqrt(1 - ecc2 * pow(sin(mLat), 2));

    final vLat = (srcLat - dstLat) * rM / pow(W, 3);
    final vLng = (srcLng - dstLng) * cos(mLat) * radiusEq / W;
    return sqrt(pow(vLat, 2) + pow(vLng, 2));
  }
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
        _tide = new CachedProp<Tide>(data, 'tide', (map) => enumByName(Tide.values, map), (v) => nameOfEnum(v)),
        _weather = new CachedProp<Weather>.forMap(data, 'weather', (map) => new Weather.fromMap(map));

  Map get asMap => _data;

  int get moon => _data['moon'];
  set moon(int v) => _data['moon'] = v;

  Tide get tide => _tide.value;
  set tide(Tide v) => _tide.value = v;

  Weather get weather => _weather.value;
  set weather(Weather v) => _weather.value = v;
}

enum Tide { Flood, High, Ebb, Low }

abstract class Tides {
  static String iconOf(Tide v) => iconBy(nameOfEnum(v));
  static String iconBy(String name) => name == null ? null : "img/tide/${name.toLowerCase()}.png";
}

abstract class MoonPhases {
  static String iconOf(int v) => v == null ? null : "img/moon/phase-${v.toString().padLeft(2, '0')}.png";
}

abstract class Weather implements JsonSupport {
  static const Map<String, String> nominalMap = const {
    'Clear': "http://openweathermap.org/img/w/01d.png",
    'Clouds': "http://openweathermap.org/img/w/02d.png",
    'Rain': "http://openweathermap.org/img/w/10d.png",
    'Show': "http://openweathermap.org/img/w/13d.png",
  };

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
        _temperature =
            new CachedProp<Temperature>.forValueUnit(data, 'temperature', (value) => new Temperature.standard(value));

  Map get asMap => _data;

  String get nominal => _data['nominal'];
  set nominal(String v) => _data['nominal'] = v;

  String get iconUrl => _data['iconUrl'];
  set iconUrl(String v) => _data['iconUrl'] = v;

  Temperature get temperature => _temperature.value;
  set temperature(Temperature v) => _temperature.value = v;
}
