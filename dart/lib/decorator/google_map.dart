library triton_note.decorator.google_map;

import 'dart:async';
import 'dart:js';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';

import 'package:triton_note/model/location.dart';

final _logger = new Logger('GoogleMaps');

@Decorator(selector: '[google-maps]')
class GoogleMap {
  static get pluginGMap => context['plugin']['google']['maps'];

  @NgOneWayOneTime('google-maps')
  var callback;

  final Element parent;
  final Completer<JsObject> _onMapReady = new Completer();
  final List<Marker> markers = [];

  GoogleMap(this.parent) {
    int zoom = 10;
    try {
      zoom = int.parse(parent.attributes['zoom']);
    } catch (ex) {}
    final fullHeight = parent.attributes['full-height'] != null;
    _logger.fine("Creating GoogleMap: element=${parent}, zoom=${zoom}, full-height=${fullHeight}");

    setZoom(zoom);
    if (fullHeight) {
      final baseHeight = window.screen.height;
      final top = parent.getBoundingClientRect().top as double;
      final value = (baseHeight - top).floor();
      _logger.fine("Make google map to full height: ${baseHeight} - ${top} = ${value}");
      parent.style.height = "${value}px";
    }
    _setDiv(parent);
    setVisible(true);
    setClickable(true);

    if (!_onMapReady.isCompleted) {
      pluginGMap['Map']
          .callMethod('getMap', [parent])
          .callMethod('on', [pluginGMap['event']['MAP_READY'], _onMapReady.complete]);
    }
    _onMapReady.future.then((gmap) {
      callback(this);
    });
  }

  _newLatLng(GeoInfo geoinfo) => new JsObject(pluginGMap['LatLng'], [geoinfo.latitude, geoinfo.longitude]);

  _gmap(String name, [List args = const []]) async {
    return (await _onMapReady.future).callMethod(name, args);
  }
  _setDiv(Element div) => _gmap('setDiv', [div]);
  setZoom(int zoom) => _gmap('setZoom', [zoom]);
  setCenter(GeoInfo geoinfo) => _gmap('setCenter', [_newLatLng(geoinfo)]);
  setVisible(bool v) => _gmap('setVisible', [v]);
  setClickable(bool value) => _gmap('setClickable', [value]);

  remove() {
    setVisible(false);
    setClickable(false);
    _setDiv(null);
    _gmap('clear');
  }

  onClick(proc(GeoInfo geoinfo)) {
    _gmap('on', [
      pluginGMap['event']['MAP_CLICK'],
      (pos, [event = null]) {
        _logger.fine("map clicked: ${pos}");
        final geoinfo = new GeoInfo.fromMap({'latitude': pos['lat'], 'longitude': pos['lng']});
        proc(geoinfo);
      }
    ]);
  }

  putMarker(GeoInfo geoinfo, [clearPrevious = false]) {
    _logger.fine("Putting marker at ${geoinfo}");
    _gmap('addMarker', [
      new JsObject.jsify({'position': _newLatLng(geoinfo)}),
      (next, [event = null]) {
        if (clearPrevious) markers.forEach((m) {
          m.remove();
        });
        markers.add(new Marker(next, geoinfo));
      }
    ]);
  }
}

class Marker {
  final _obj;
  GeoInfo geoinfo;

  Marker(this._obj, this.geoinfo);

  remove() => _obj.callMethod('remove', []);
}
