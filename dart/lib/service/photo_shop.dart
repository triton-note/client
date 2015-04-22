library photo_shop;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:triton_note/model/photo.dart';
import 'package:triton_note/model/location.dart';

class PhotoShop {
  final Completer<Blob> _onChoose = new Completer();
  final Completer<Photo> _onGetUrl = new Completer();
  final Completer<GeoInfo> _onGetGeoinfo = new Completer();
  final Completer<DateTime> _onGetTimestamp = new Completer();

  Future<Blob> get photo => _onChoose.future;
  Future<Photo> get photoUrl => _onGetUrl.future;
  Future<GeoInfo> get geoinfo => _onGetGeoinfo.future;
  Future<DateTime> get timestamp => _onGetTimestamp.future;

  _makeUrl(Blob blob) async {
    final String url = Url.createObjectUrlFromBlob(blob);
    _onGetUrl.complete(new Photo.fromMap({'original': new Image.fromMap({'url': url}), 'mainview': new Image.fromMap({'url': url})}));
  }

  _readExif(array) async {
    final reader = new JsObject(context['ExifReader'], []);
    reader.callMethod('load', [array]);

    try {
      final text = reader.callMethod('getTagDescription', ['DateTimeOriginal']);
      final a = text.split(' :').map(int.parse);
      final date = new DateTime(a[0], a[1], a[2], a[3], a[4], a[5]);
      _onGetTimestamp.complete(date);
    } catch (ex) {
      _onGetTimestamp.complete(null);
    }
    try {
      final lat = int.parse(reader.callMethod('getTagDescription', ['GPSLatitude']));
      final lon = int.parse(reader.callMethod('getTagDescription', ['GPSLongitude']));
      final info = (lat != null && lon != null) ? new GeoInfo.fromMap({'latitude': lat, 'longitude': lon}) : null;
      _onGetGeoinfo.complete(info);
    } catch (ex) {
      _onGetGeoinfo.complete(null);
    }
  }

  Future<Blob> choose() async {
    try {
      print("Choosing photo: ${context['navigator']['camera']}");
      context['navigator']['camera'].callMethod('getPicture', [
        (String uri) async {
          try {
            print("Resolving file uri: ${uri}");
            context['window'].callMethod('resolveLocalFileSystemURL', [
              uri,
              (entry) {
                print("Loading file entry: ${entry}");
                try {
                  entry.file((file) {
                    try {
                      print("Reading file: ${file}");
                      final reader = new JsObject(context['FileReader'], []);
                      reader['onloadend'] = (event) {
                        try {
                          final array = event['target']['result'];
                          print("Array of file(${uri}): ${array}");
                          final blob = new Blob([array], 'image/jpeg');
                          _onChoose.complete(blob);
                          _makeUrl(blob);
                          _readExif(array);
                        } catch (ex) {
                          _onChoose.completeError(ex);
                        }
                      };
                      reader['onerror'] = _onChoose.completeError;
                      reader.callMethod('readAsArrayBuffer', [file]);
                    } catch (ex) {
                      _onChoose.completeError(ex);
                    }
                  });
                } catch (ex) {
                  _onChoose.completeError(ex);
                }
              }
            ]);
          } catch (ex) {
            _onChoose.completeError(ex);
          }
        },
        _onChoose.completeError,
        {
          'mediaType': context['navigator']['camera']['MediaType']['PICTURE'],
          'encodingType': context['Camera']['EncodingType']['JPEG'],
          'sourceType': context['Camera']['PictureSourceType']['PHOTOLIBRARY'],
          'destinationType': context['Camera']['DestinationType']['FILE_URI'],
          'correctOrientation': true
        }
      ]);
    } catch (ex) {
      _onChoose.completeError(ex);
    }
    return photo;
  }
}
