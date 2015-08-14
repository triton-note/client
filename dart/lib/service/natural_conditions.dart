library triton_note.service.natural_conditions;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/util/enums.dart';
import 'package:triton_note/settings.dart';
import 'package:triton_note/service/aws/lambda.dart';

final _logger = new Logger('NaturalConditions');

class NaturalConditions {
  static Tide _tideState(double degOrigin, double degMoon) {
    final angle = ((degMoon - degOrigin + 15) + 180) % 180;
    _logger.fine("TideMoon origin(${degOrigin}) -> moon(${degMoon}): ${angle}");
    if (angle < 30) return Tide.High;
    if (angle <= 90) return Tide.Flood;
    if (angle < 120) return Tide.Low;
    return Tide.Ebb;
  }

  static Future<Condition> at(DateTime date, GeoInfo geoinfo) async {
    final weatherWait = _OpenWeatherMap.at(geoinfo, date);

    final moon = await _Moon.at(date);
    final Tide tide = _tideState(geoinfo.longitude, moon.earthLongitude);

    final result = new Condition.fromMap({'moon': moon.age.round(), 'tide': nameOfEnum(tide)});

    final weather = await weatherWait;
    if (weather != null) result.weather = weather;
    return result;
  }
}

class _Moon {
  static Future<_Moon> at(DateTime date) async {
    final map = await Lambda.MOON({'date': date.toUtc().millisecondsSinceEpoch.toString()});
    return new _Moon(map);
  }

  _Moon(this._src);
  final Map _src;

  double get age => _src['age'];
  double get earthLongitude => _src['earth-longitude'];
}

class _OpenWeatherMap {
  static Future<String> icon(String id) async => "${(await Settings).openweathermap.iconUrl}/${id}.png";

  static Future<Weather> at(GeoInfo geoinfo, DateTime date) async {
    final map = await Lambda.WEATHER({
      'apiKey': (await Settings).openweathermap.apiKey,
      'date': date.toUtc().millisecondsSinceEpoch.toString(),
      'lat': geoinfo.latitude.toStringAsFixed(8),
      'lng': geoinfo.longitude.toStringAsFixed(8)
    });
    return (map.isEmpty)
        ? null
        : new Weather.fromMap({
      'nominal': map['nominal'],
      'iconUrl': await icon(map['iconId']),
      'temperature': {'unit': nameOfEnum(TemperatureUnit.Cels), 'value': map['temperature']}
    });
  }
}
