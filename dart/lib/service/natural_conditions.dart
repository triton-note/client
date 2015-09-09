library triton_note.service.natural_conditions;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/location.dart';
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
  static final Future<Lambda<_Moon>> _lambda = Settings.then((s) {
    loader(Map map) => new _Moon(map['age'].toDouble(), map['earth-longitude'].toDouble());

    return new Lambda<_Moon>(s.lambda.moon, loader);
  });

  static Future<_Moon> at(DateTime date) async =>
      (await _lambda)({'date': date.toUtc().millisecondsSinceEpoch.toString()});

  _Moon(this.age, this.earthLongitude);

  final double age;
  final double earthLongitude;
}

class _OpenWeatherMap {
  static final Future<Lambda<Weather>> _lambda = Settings.then((s) {
    loader(Map map) => (map.isEmpty)
        ? null
        : new Weather.fromMap({
      'nominal': map['nominal'].toString(),
      'iconUrl': "${s.openweathermap.iconUrl}/${map['iconId'].toString()}.png",
      'temperature': map['temperature'].toDouble()
    });
    return new Lambda(s.lambda.weather, loader);
  });

  static Future<Weather> at(GeoInfo geoinfo, DateTime date) async => (await _lambda)({
    'apiKey': (await Settings).openweathermap.apiKey,
    'date': date.toUtc().millisecondsSinceEpoch.toString(),
    'lat': geoinfo.latitude.toStringAsFixed(8),
    'lng': geoinfo.longitude.toStringAsFixed(8)
  });
}
