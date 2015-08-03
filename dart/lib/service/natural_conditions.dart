library triton_note.service.natural_conditions;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:logging/logging.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/util/enums.dart';
import 'package:triton_note/settings.dart';

final _logger = new Logger('NaturalConditions');

class NaturalConditions {
  static final _OpenWeatherMap _weather = new _OpenWeatherMap(const Duration(seconds: 30), 3);

  static Tide _tideState(double degOrigin, double degMoon) {
    final angle = ((degMoon - degOrigin + 15) + 180) % 180;
    _logger.fine("TideMoon origin(${degOrigin}) -> moon(${degMoon}): ${angle}");
    if (angle < 30) return Tide.High;
    if (angle <= 90) return Tide.Flood;
    if (angle < 120) return Tide.Low;
    return Tide.Ebb;
  }

  static Future<Condition> at(DateTime date, GeoInfo geoinfo) async {
    final weatherWait = _weather(geoinfo, date);

    final moon = await _Moon.at(date);
    final Tide tide = _tideState(geoinfo.longitude, moon.earthLongitude);
    final map = {'moon': {'N': moon.age.toString()}, 'tide': {'S': nameOfEnum(tide)}};

    final weather = await weatherWait;
    if (weather != null) map['weather'] = {'M': weather};
    return new Condition.fromMap(map);
  }
}

class _Moon {
  static Future<String> get url async => (await Settings).lambda.moon.url;
  static Future<_Moon> at(DateTime date) async {
    final result = new Completer();
    final req = new HttpRequest()
      ..open('POST', await url)
      ..setRequestHeader('x-api-key', (await Settings).lambda.moon.key)
      ..send({'date': date.toUtc().millisecondsSinceEpoch});
    req.onLoadEnd.listen((event) {
      final text = req.responseText;
      _logger.finest("Response: ${text}");
      result.complete(new _Moon(JSON.decode(text)));
    });
    req.onError.listen((event) => result.completeError(req.responseText));
    req.onTimeout.listen((event) => result.completeError(event));
    return result.future;
  }

  _Moon(this._src);
  final Map _src;

  int get age => _src['age'];
  double get earthLongitude => _src['earthLongitude'];
}

class _OpenWeatherMap {
  final Duration delay;
  final int countMax;

  _OpenWeatherMap(this.delay, this.countMax);

  Future<String> get url async => (await Settings).openweathermap.url;
  Future<String> get apiKey async => (await Settings).openweathermap.apiKey;
  Future<String> icon(String id) async => "${(await Settings).openweathermap.iconUrl}/${id}.png";

  Future<Map> _get(String path, GeoInfo geoinfo, [Map<String, String> params = const {}]) async {
    params['APPID'] = await apiKey;
    params['lat'] = geoinfo.latitude.toStringAsFixed(8);
    params['lon'] = geoinfo.longitude.toStringAsFixed(8);

    task() async {
      final result = new Completer();
      final req = new HttpRequest()
        ..open('GET', await url)
        ..send(params);
      req.onLoadEnd.listen((event) {
        final text = req.responseText;
        _logger.finest("Response: ${text}");
        result.complete(JSON.decode(text));
      });
      req.onError.listen((event) => result.completeError(req.responseText));
      req.onTimeout.listen((event) => result.completeError(event));
      return result.future;
    }

    retry(int count) async {
      try {
        return await task();
      } catch (ex) {
        if (count > 0) return await retry(count - 1);
        throw ex;
      }
    }
    return await retry(countMax);
  }

  Future<Weather> past(GeoInfo geoinfo, DateTime date) async {
    final res = await _get("history/city", geoinfo, {
      'type': "hour",
      'start': (date.millisecondsSinceEpoch / 1000).toString(),
      'cnt': "1"
    });
    if (res['cnt'] < 1) return null;
    return _makeWeather(res['list'][0]);
  }
  Future<Weather> current(GeoInfo geoinfo) async {
    final res = await _get("weather", geoinfo);
    return _makeWeather(res);
  }

  Future<Weather> call(GeoInfo geoinfo, DateTime date) async {
    if (date.toUtc().difference(new DateTime.now().toUtc()).inHours < 3) {
      return current(geoinfo);
    } else {
      return past(geoinfo, date.toUtc());
    }
  }

  Weather _makeWeather(Map json) {
    final w = json['weather'][0];
    final tv = json['main']['temp'] - 273.15;
    return new Weather.fromMap({
      'nominal': {'S': w['main']},
      'iconUrl': {'S': icon(w['icon'])},
      'temperature': {'M': {'unit': {'S': nameOfEnum(TemperatureUnit.Cels)}, 'value': {'N': tv.toString()}}}
    });
  }
}
