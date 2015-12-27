library triton_note.service.geolocation;

import 'dart:async';
import 'dart:js';

import 'package:logging/logging.dart';
import 'package:triton_note/model/location.dart';

final Logger _logger = new Logger('Geolocation');

GeoInfo get defaultLocation => new GeoInfo.fromMap({'latitude': 37.971751, 'longitude': 23.726720});
const defaultTimeout = const Duration(seconds: 10);

Future<GeoInfo> location([Duration timeout = defaultTimeout, GeoInfo orElse = null]) async {
  final result = new Completer<GeoInfo>();
  done([GeoInfo location = null]) {
    if (!result.isCompleted) {
      if (location == null) {
        result.complete(orElse != null ? orElse : defaultLocation);
      } else {
        result.complete(location);
      }
    }
  }

  final geo = context['navigator']['geolocation'];
  if (geo != null) {
    _logger.info("Getting current location...");
    geo.callMethod('getCurrentPosition', [
      (pos) {
        done(new GeoInfo.fromMap({'latitude': pos['coords']['latitude'], 'longitude': pos['coords']['longitude']}));
      },
      (error) {
        _logger.warning("Error on getting location: ${error['message']}");
        done();
      },
      new JsObject.jsify({'maximumAge': 3000, 'timeout': timeout.inMilliseconds, 'enableHighAccuracy': true})
    ]);
    new Future.delayed(timeout, () {
      _logger.warning("Getting location is Timeout");
      done();
    });
  } else {
    _logger.info("Geolocation is not supported.");
    done();
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
