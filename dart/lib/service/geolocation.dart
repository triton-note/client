library triton_note.service.geolocation;

import 'dart:async';
import 'dart:js';

import 'package:logging/logging.dart';
import 'package:triton_note/model/location.dart';

final Logger _logger = new Logger('Geolocation');

GeoInfo get defaultLocation => new GeoInfo.fromMap({'latitude': 37.971751, 'longitude': 23.726720});
const defaultTimeout = const Duration(seconds: 5);

Future<GeoInfo> location([Duration timeout = defaultTimeout, GeoInfo orElse = null]) async {
  try {
    return await getHere(timeout);
  } catch (ex) {
    final result = orElse ?? defaultLocation;
    _logger.warning(() => "Use default location (${result}). since error on getting location: ${ex}");
    return result;
  }
}

Future<GeoInfo> getHere([Duration timeout = defaultTimeout]) async {
  final result = new Completer<GeoInfo>();

  final geo = context['navigator']['geolocation'];
  if (geo != null) {
    _logger.info("Getting current location...");
    geo.callMethod('getCurrentPosition', [
      (pos) {
        if (!result.isCompleted) result.complete(
            new GeoInfo.fromMap({'latitude': pos['coords']['latitude'], 'longitude': pos['coords']['longitude']}));
      },
      (error) {
        if (!result.isCompleted) result.completeError(error['message']);
      },
      new JsObject.jsify({'maximumAge': 3000, 'timeout': timeout.inMilliseconds, 'enableHighAccuracy': true})
    ]);
    new Future.delayed(timeout, () {
      if (!result.isCompleted) result.completeError("Getting location is Timeout");
    });
  } else {
    if (!result.isCompleted) result.completeError("Geolocation is not supported.");
  }

  return result.future;
}

Future<bool> get isEnabled async {
  final result = new Completer<bool>();

  context['cordova']['plugins']['diagnostic'].callMethod('isLocationEnabled', [
    (enabled) {
      _logger.finest(() => "Result of isLocationEnabled: ${enabled}");
      result.complete(enabled == 1);
    },
    (error) {
      _logger.warning(() => "Error on isLocationEnabled: ${error}");
      result.complete(false);
    }
  ]);

  return result.future;
}

switchToLocationSettings() {
  context['cordova']['plugins']['diagnostic'].callMethod('switchToLocationSettings', []);
}
