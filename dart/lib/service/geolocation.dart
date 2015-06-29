library triton_note.service.geolocation;

import 'dart:async';
import 'dart:js';

import 'package:logging/logging.dart';
import 'package:triton_note/model/location.dart';

final _logger = new Logger('Geolocation');

Future<GeoInfo> location() async {
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
        if (!result.isCompleted) result.completeError(error);
      },
      new JsObject.jsify({'maximumAge': 3000, 'timeout': 5000, 'enableHighAccuracy': true})
    ]);
  } else {
    _logger.info("Geolocation is not supported.");
    result.completeError("Geolocation is not supported.");
  }

  return result.future;
}
