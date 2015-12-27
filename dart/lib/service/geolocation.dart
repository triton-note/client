library triton_note.service.geolocation;

import 'dart:async';
import 'dart:js';

import 'package:logging/logging.dart';
import 'package:triton_note/model/location.dart';

final _logger = new Logger('Geolocation');

Future<GeoInfo> location([orElse = const {'latitude': 37.971751, 'longitude': 23.726720}]) async {
  final result = new Completer<GeoInfo>();

  final geo = context['navigator']['geolocation'];
  if (geo != null) {
    _logger.info("Getting current location...");
    geo.callMethod('getCurrentPosition', [
      (pos) {
        result.complete(
            new GeoInfo.fromMap({'latitude': pos['coords']['latitude'], 'longitude': pos['coords']['longitude']}));
      },
      (error) {
        _logger.fine("Geolocation Error: ${error['message']}");
        if (!result.isCompleted) {
          if (orElse != null) {
            _logger.info("Use default value: ${orElse}");
            result.complete(new GeoInfo.fromMap(orElse));
          } else {
            result.completeError(error);
          }
        }
      },
      new JsObject.jsify({'maximumAge': 3000, 'timeout': 5000, 'enableHighAccuracy': true})
    ]);
  } else {
    _logger.info("Geolocation is not supported.");
    result.completeError("Geolocation is not supported.");
  }

  return result.future;
}

Future<bool> get isEnabled async {
  final result = new Completer<bool>();

  context['cordova']['plugins']['diagnostic'].callMethod('isLocationEnabled', [
    (enabled) {
      result.complete(enabled);
    },
    (error) {
      result.completeError(error);
    }
  ]);

  return result.future;
}

switchToLocationSettings() {
  context['cordova']['plugins']['diagnostic'].callMethod('switchToLocationSettings', []);
}
