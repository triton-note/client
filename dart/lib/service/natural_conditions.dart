library triton_note.service.natural_conditions;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/settings.dart';
import 'package:triton_note/service/aws/api_gateway.dart';

final _logger = new Logger('NaturalConditions');

class NaturalConditions {
  static Future<Weather> weather(GeoInfo geoinfo, DateTime date) async => _OpenWeatherMap.at(geoinfo, date);

  static Future<MoonPhase> moon(DateTime date) async => _Moon.at(date);
}

class _Moon {
  static final Future<ApiGateway<MoonPhase>> _server = Settings.then((s) {
    loader(Map map) => new MoonPhase.fromMap(map);

    return new ApiGateway<MoonPhase>(s.server.moon, loader);
  });

  static Future<MoonPhase> at(DateTime date) async =>
      (await _server)({'date': date.toUtc().millisecondsSinceEpoch.toString()});
}

class _OpenWeatherMap {
  static final Future<ApiGateway<Weather>> _server = Settings.then((s) {
    loader(Map map) => (map.isEmpty)
        ? null
        : new Weather.fromMap({
            'nominal': map['name'].toString(),
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
