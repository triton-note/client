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

final _gmaps = context['google']['maps'];

Future<GoogleMap> makeMap(Element div, GeoInfo center, {int zoom: 8, bool disableDefaultUI: true}) async {
  await _append();

  final options = {
    'center': {'lat': center.latitude, 'lng': center.longitude},
    'zoom': zoom,
    'disableDefaultUI': disableDefaultUI
  };

  final g = new JsObject(_gmaps['Map'], [div, new JsObject.jsify(options)]);
  return new GoogleMap(g, div);
}

JsObject _toLatLng(GeoInfo pos) => new JsObject(_gmaps['LatLng'], [pos.latitude, pos.longitude]);
GeoInfo _fromLatLng(latLng) => new GeoInfo.fromMap({'latitide': latLng['lat'], 'longitude': latLng['lng']});

class GoogleMap {
  final JsObject _src;
  final Element hostElement;

  var _clickListener;

  final List<Marker> _markers = [];

  GoogleMap(this._src, this.hostElement) {
    _gmaps['event'].callMethod('addListener', [
      _src,
      'click',
      (mouseEvent) {
        _logger.finest("Clicked: ${mouseEvent}");
        if (_clickListener != null) _clickListener(_fromLatLng(mouseEvent['latLng']));
      }
    ]);
  }

  set center(GeoInfo pos) {
    _logger.fine("Setting gmap center: ${pos}");
    _src.callMethod('setCenter', [_toLatLng(pos)]);
  }

  clearMarkers() {
    _markers.forEach((m) => m.remove());
  }
  putMarker(GeoInfo pos) {
    final marker = new Marker(pos, map: this, draggable: false);
    _markers.add(marker);
    return marker;
  }
  dropMarker(GeoInfo pos, [int bounce = 8]) async {
    final marker =
        new Marker(pos, map: this, draggable: false, animation: (bounce > 0) ? Animation.BOUNCE : Animation.DROP);
    if (bounce > 0) new Future.delayed(new Duration(milliseconds: 8 * 750), () {
      marker.animation = null;
    });
    _markers.add(marker);
    return marker;
  }

  set onClick(void proc(GeoInfo pos)) => _clickListener = proc;

  trigger(String name) => _gmaps['event'].callMethod('trigger', [_src, name]);
  triggerResize() => trigger('resize');
}

class Marker {
  static Map makeIcon(String iconUrl, {int sizeW, int sizeH, int originX, int originY, int anchorX, int anchorY}) {
    var size, origin, anchor;
    if (sizeW != null && sizeH != null) size = new JsObject(_gmaps['Size'], [sizeW, sizeH]);
    if (originX != null && originY != null) origin = new JsObject(_gmaps['Point'], [originX, originY]);
    if (anchorX != null && anchorY != null) anchor = new JsObject(_gmaps['Point'], [anchorX, anchorY]);
    return (size == null && origin == null && anchor == null)
        ? iconUrl
        : {'url': iconUrl, 'size': size, 'origin': origin, 'anchor': anchor};
  }

  final GeoInfo position;
  final JsObject _src;

  Marker(GeoInfo pos, {GoogleMap map, bool draggable, Animation animation, String title, int zIndex, String iconUrl})
      : this.position = pos,
        this._src = new JsObject(_gmaps['Marker'], [
          new JsObject.jsify({
            'position': _toLatLng(pos),
            'map': map._src,
            'draggable': draggable,
            'animation': animation._src,
            'title': title,
            'zIndex': zIndex,
            'icon': makeIcon(iconUrl)
          })
        ]);

  set animation(Animation a) => _src.callMethod('setAnimation', [a]);

  set map(GoogleMap map) => _src.callMethod('setMap', [map._src]);

  void remove() => map = null;
}

class Animation {
  static final BOUNCE = new Animation._of(_gmaps['Animation']['BOUNCE']);
  static final DROP = new Animation._of(_gmaps['Animation']['DROP']);

  final JsObject _src;

  Animation._of(this._src);
}
