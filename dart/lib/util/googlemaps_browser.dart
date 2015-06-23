library triton_note.util.googlemaps;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/service/geolocation.dart' as Geo;
import 'package:triton_note/settings.dart';

Completer<Null> _onAppended = null;

Future<Null> _append() async {
  if (_onAppended == null) {
    _onAppended = new Completer();

    final initializer = 'triton_note_initialize_googlemaps';
    context[initializer] = () {
      print("Google Maps API is initialized.");
      _onAppended.complete();
    };

    final elem = document.createElement('script');
    elem.type = 'text/javascript';
    elem.src = "https://maps.googleapis.com/maps/api/js?v=3&key=${await Settings.googleKey}&callback=${initializer}";

    final first = document.getElementsByTagName('script')[0];
    first.parentNode.insertBefore(elem, first);
  }
  return _onAppended.future;
}

class GoogleMaps {
  final Completer _onInitialized = new Completer();
  final Element div;

  GoogleMaps(this.div, {GeoInfo center: null, zoom: 8, disableDefaultUI: true}) {
    _initialize(center, zoom, disableDefaultUI);
  }

  _initialize(GeoInfo center, int zoom, bool disableDefaultUI) async {
    await _append();

    if (center == null) center = await Geo.location();
    final options = {
      'center': {'lat': center.latitude, 'lng': center.longitude},
      'zoom': zoom,
      'disableDefaultUI': disableDefaultUI
    };

    final g = new JsObject(context['google']['maps']['Map'], [div, new JsObject.jsify(options)]);
    _onInitialized.complete(g);
  }

  dropMarker(GeoInfo pos) async {
    final gmap = await _onInitialized.future;
    final marker = new JsObject(context['google']['maps']['Marker'], [
      new JsObject.jsify({
        'position': {'lat': pos.latitude, 'lng': pos.longitude},
        'map': gmap,
        'draggable': false,
        'animation': context['google']['maps']['Animation']['BOUNCE']
      })
    ]);
    new Future.delayed(new Duration(milliseconds: 8 * 750), () {
      marker.callMethod('setAnimation', [null]);
    });
  }
}
