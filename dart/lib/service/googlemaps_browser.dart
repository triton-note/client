library triton_note.service.googlemaps;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:logging/logging.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/util/geometry.dart';
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
        "https://maps.googleapis.com/maps/api/js?v=3&key=${(await Settings).googleKey}&sensor=true&callback=${initializer}";

    final first = document.getElementsByTagName('script')[0];
    first.parentNode.insertBefore(elem, first);
  }
  return _onAppended.future;
}

Future<GoogleMap> makeGoogleMap(Element div, GeoInfo center, {int zoom: 8, bool disableDefaultUI: true}) async {
  await _append();

  final options = {'center': _toLatLng(center), 'zoom': zoom, 'disableDefaultUI': disableDefaultUI};

  final g = new JsObject(context['google']['maps']['Map'], [div, new JsObject.jsify(options)]);
  return new GoogleMap(g, options, div);
}

JsObject _toLatLng(GeoInfo pos) =>
    pos == null ? null : new JsObject(context['google']['maps']['LatLng'], [pos.latitude, pos.longitude]);
GeoInfo _fromLatLng(JsObject latLng) => latLng == null
    ? null
    : new GeoInfo.fromMap({'latitude': latLng.callMethod('lat', []), 'longitude': latLng.callMethod('lng', [])});

abstract class Wrapper {
  JsObject get _src;
}

class GoogleMap implements Wrapper {
  final JsObject _src;
  final MapOptions options;
  final Element hostElement;

  final List<Marker> _markers = [];

  GoogleMap(JsObject src, Map options, this.hostElement)
      : this._src = src,
        this.options = new MapOptions(src, options) {}

  GeoInfo get center {
    final pos = _src.callMethod('getCenter', []);
    return _fromLatLng(pos);
  }
  set center(GeoInfo pos) {
    _logger.fine("Setting gmap center: ${pos}");
    _src.callMethod('setCenter', [_toLatLng(pos)]);
  }

  LatLngBounds get bounds {
    final a = _src.callMethod('getBounds', []);
    return (a == null || a.callMethod('isEmpty', [])) ? null : new LatLngBounds(a);
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

  double get zoom => _src.callMethod('getZoom', []);
  set zoom(double v) => _src.callMethod('setZoom', [v]);

  set onClick(void proc(GeoInfo pos)) => on('click', (event) => proc(_fromLatLng(event['latLng'])));

  void on(String name, proc) {
    context['google']['maps']['event'].callMethod('addListener', [_src, name, proc]);
  }

  trigger(String name) => context['google']['maps']['event'].callMethod('trigger', [_src, name]);
  triggerResize() => trigger('resize');
}

class MapOptions {
  final JsObject _gmap;
  final Map _src;

  MapOptions(this._gmap, this._src);

  get(String name) => _src[name];
  put(String name, value) {
    _src[name] = value;
    _gmap.callMethod('setOptions', [new JsObject.jsify(_src)]);
    return value;
  }

  bool get mapTypeControl => _src['mapTypeControl'];
  set mapTypeControl(bool v) => put('mapTypeControl', v);
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

class LatLngBounds {
  LatLngBounds(JsObject src) : this._src = src {
    _sw = _fromLatLng(src.callMethod('getSouthWest', []));
    _ne = _fromLatLng(src.callMethod('getNorthEast', []));
    _iLat = new ClosedInterval(_sw.latitude, _ne.latitude);
    _iLng = new ClosedInterval(_sw.longitude, _ne.longitude);
  }

  final JsObject _src;
  GeoInfo _sw, _ne;
  ClosedInterval _iLat, _iLng;

  @override
  String toString() => "Bounds(SouthWest: ${_sw}, NorthEast: ${_ne})";

  GeoInfo get southWest => _sw;
  GeoInfo get northEast => _ne;
  ClosedInterval get intervalLatitude => _iLat;
  ClosedInterval get intervalLongitude => _iLng;

  bool contains(GeoInfo o) => _iLat.contains(o.latitude) && _iLng.contains(o.longitude);
}
