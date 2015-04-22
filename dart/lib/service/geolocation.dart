library geolocation;

import 'dart:async';
import 'dart:js';

import 'package:triton_note/model/location.dart';

Future<GeoInfo> location() async {
  final result = new Completer<GeoInfo>();

  context['navigator']['geolocation'].callMethod('getCurrentPosition', [
    (pos) {
      result.complete(new GeoInfo.fromMap({'latitude': pos['coords']['latitude'], 'longitude': pos['coords']['longitude']}));
    },
    result.completeError,
    new JsObject.jsify({'maximumAge': 3000, 'timeout': 5000, 'enableHighAccuracy': true})
  ]);

  return result.future;
}
