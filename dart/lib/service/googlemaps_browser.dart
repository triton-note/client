library triton_note.service.googlemaps;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:logging/logging.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/settings.dart';

final _logger = new Logger('GoogleMaps');

Completer<Null> _onAppended = null;

Future<Null> _append() async {
  if (_onAppended == null) {
    _onAppended = new Completer();

    final initializer = 'triton_note_initialize_googlemaps';
    context[initializer] = () {
      _logger.info("Google Maps API is initialized.");
      _onAppended.complete();
    };

    final elem = document.createElement('script');
    elem.type = 'text/javascript';
    elem.src =
        "https://maps.googleapis.com/maps/api/js?v=3&key=${await Settings.googleKey}&sensor=true&callback=${initializer}";

    final first = document.getElementsByTagName('script')[0];
    first.parentNode.insertBefore(elem, first);
  }
  return _onAppended.future;
}

Future<GoogleMap> makeGoogleMap(Element div, GeoInfo center, {int zoom: 8, bool disableDefaultUI: true}) async {
  await _append();

  final options = {'center': _toLatLng(center), 'zoom': zoom, 'disableDefaultUI': disableDefaultUI};

  final g = new JsObject(context['google']['maps']['Map'], [div, new JsObject.jsify(options)]);
  return new GoogleMap(g, div);
}

JsObject _toLatLng(GeoInfo pos) => new JsObject(context['google']['maps']['LatLng'], [pos.latitude, pos.longitude]);
GeoInfo _fromLatLng(JsObject latLng) =>
    new GeoInfo.fromMap({'latitude': latLng.callMethod('lat', []), 'longitude': latLng.callMethod('lng', [])});

abstract class Wrapper {
  JsObject get _src;
}

class GoogleMap implements Wrapper {
  final JsObject _src;
  final Element hostElement;

  var _clickListener;

  final List<Marker> _markers = [];

  GoogleMap(this._src, this.hostElement) {
    context['google']['maps']['event'].callMethod('addListener', [
      _src,
      'click',
      (mouseEvent) {
        _logger.finest("Clicked: ${mouseEvent}");
        if (_clickListener != null) _clickListener(_fromLatLng(mouseEvent['latLng']));
      }
    ]);
  }

  GeoInfo get center {
    final pos = _src.callMethod('getCenter', []);
    return _fromLatLng(pos);
  }
  set center(GeoInfo pos) {
    _logger.fine("Setting gmap center: ${pos}");
    _src.callMethod('setCenter', [_toLatLng(pos)]);
  }

  panTo(GeoInfo pos) {
    _src.callMethod('panTo', [_toLatLng(pos)]);
  }

  clearMarkers() {
    _markers.forEach((m) => m.remove());
  }
  putMarker(GeoInfo pos, [Map options = const {}]) {
    final marker = new Marker(pos, this, options);
    _markers.add(marker);
    return marker;
  }

  set onClick(void proc(GeoInfo pos)) => _clickListener = proc;

  trigger(String name) => context['google']['maps']['event'].callMethod('trigger', [_src, name]);
  triggerResize() => trigger('resize');
}

class Marker implements Wrapper {
  static Map collectOptions(Map src, Map alpha) {
    final result = {};
    new Map.from(alpha)
      ..addAll(src)
      ..forEach((name, value) {
        if (value != null) {
          if (value is Wrapper) value = value._src;
          if (value is GeoInfo) value = _toLatLng(value);
          result[name] = value;
        }
      });
    _logger.finest("Created marker options: ${result}");
    return result;
  }
  final GeoInfo position;
  final JsObject _src;

  Marker(GeoInfo pos, GoogleMap gmap, Map options)
      : this.position = pos,
        this._src = new JsObject(context['google']['maps']['Marker'],
            [new JsObject.jsify(collectOptions(options, {'map': gmap, 'position': pos}))]);

  set map(GoogleMap map) => _src.callMethod('setMap', [map == null ? null : map._src]);

  void remove() => map = null;
}
