library triton_note.service.natural_conditions;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/util/enums.dart';
import 'package:triton_note/settings.dart';
import 'package:triton_note/service/aws/api_gateway.dart';

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
  static final Future<ApiGateway<_Moon>> _server = Settings.then((s) {
    loader(Map map) => new _Moon(map['age'].toDouble(), map['earth-longitude'].toDouble());

    return new ApiGateway<_Moon>(s.server.moon, loader);
  });

  static Future<_Moon> at(DateTime date) async =>
      (await _server)({'date': date.toUtc().millisecondsSinceEpoch.toString()});

  _Moon(this.age, this.earthLongitude);

  final double age;
  final double earthLongitude;
}

class _OpenWeatherMap {
  static final Future<ApiGateway<Weather>> _server = Settings.then((s) {
    loader(Map map) => (map.isEmpty)
        ? null
        : new Weather.fromMap({
            'nominal': map['nominal'].toString(),
            'iconUrl': map['iconUrl'].toString(),
            'temperature': map['temperature'].toDouble()
          });
    return new ApiGateway(s.server.weather, loader);
  });

  static Future<Weather> at(GeoInfo geoinfo, DateTime date) async => (await _server)({
        'bucketName': (await Settings).s3Bucket,
        'date': date.toUtc().millisecondsSinceEpoch.toString(),
        'latitude': geoinfo.latitude.toStringAsFixed(8),
        'longitude': geoinfo.longitude.toStringAsFixed(8)
      });
}
