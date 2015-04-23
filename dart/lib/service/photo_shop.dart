library photo_shop;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:triton_note/model/photo.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/util/binary_data.dart';

class PhotoShop {
  final Completer<Blob> _onChoose = new Completer();
  final Completer<Photo> _onGetUrl = new Completer();
  final Completer<GeoInfo> _onGetGeoinfo = new Completer();
  final Completer<DateTime> _onGetTimestamp = new Completer();

  final cameraOptions = {
    'mediaType': context['navigator']['camera']['MediaType']['PICTURE'],
    'encodingType': context['Camera']['EncodingType']['JPEG'],
    'sourceType': context['Camera']['PictureSourceType']['PHOTOLIBRARY'],
    'destinationType': context['Camera']['DestinationType']['FILE_URI'],
    'correctOrientation': true
  };

  Future<Blob> get photo => _onChoose.future;
  Future<Photo> get photoUrl => _onGetUrl.future;
  Future<GeoInfo> get geoinfo => _onGetGeoinfo.future;
  Future<DateTime> get timestamp => _onGetTimestamp.future;

  _makeUrl() async {
    try {
      final String url = Url.createObjectUrlFromBlob(await photo);
      print("Url of blob: ${url}");
      _onGetUrl.complete(new Photo.fromMap({'original': {'url': url}, 'mainview': {'url': url}}));
    } catch (ex) {
      _onGetUrl.completeError(ex);
    }
  }

  _readExif(array) {
    try {
      print("Exif Loading...");
      final data = new JsObject(context['DataView'], [array, 0, 128 * 1024]);
      print("DataView length=${data['byteLength']}");
      final exif = new JsObject(context['ExifReader'], []);
      exif.callMethod('loadView', [data]);

      try {
        String text = exif.callMethod('getTagDescription', ['DateTimeOriginal']);
        if (text == null) text = exif.callMethod('getTagDescription', ['DateTimeDigitized']);
        if (text == null) text = exif.callMethod('getTagDescription', ['DateTime']);
        final a = text.split(' ').expand((e) => e.split(':')).map(int.parse).toList();
        print("Exif: Timestamp: ${a}");
        final date = new DateTime(a[0], a[1], a[2], a[3], a[4], a[5]);
        _onGetTimestamp.complete(date);
      } catch (ex) {
        print("Exif: Timestamp: Error: ${ex}");
        _onGetTimestamp.complete(null);
      }
      try {
        final double lat = exif.callMethod('getTagDescription', ['GPSLatitude']);
        final double lon = exif.callMethod('getTagDescription', ['GPSLongitude']);
        print("Exif: GPS: ${lat}, ${lon}");
        final info = (lat != null && lon != null) ? new GeoInfo.fromMap({'latitude': lat, 'longitude': lon}) : null;
        _onGetGeoinfo.complete(info);
      } catch (ex) {
        print("Exif: GPS: Error: ${ex}");
        _onGetGeoinfo.complete(null);
      }
    } catch (ex) {
      print("Exif: Error: ${ex}");
      _onGetTimestamp.complete(null);
      _onGetGeoinfo.complete(null);
    }
  }

  Future<Blob> choose() {
    _makeUrl();
    try {
      print("Choosing photo: ${cameraOptions}");
      context['navigator']['camera'].callMethod('getPicture', [
        (String uri) {
          try {
            print("Resolving file uri: ${uri}");
            context.callMethod('resolveLocalFileSystemURL', [
              uri,
              (entry) {
                print("Loading file entry: ${entry}");
                try {
                  entry.callMethod('file', [
                    (File file) {
                      print("Reading file: ${file.name} size=${file.size}");
                      final reader = new JsObject(context['FileReader'], []);
                      reader['onload'] = (event) {
                        try {
                          final array = reader['result'];
                          final blob = new Blob([fromArrayBuffer(array)], 'image/jpeg');
                          _onChoose.complete(blob);
                          new Future.delayed(new Duration(milliseconds: 100), () {
                            _readExif(array);
                          });
                        } catch (ex) {
                          _onChoose.completeError(ex);
                        }
                      };
                      reader['onerror'] = (event) {
                        _onChoose.completeError(reader['error']);
                      };
                      reader.callMethod('readAsArrayBuffer', [file]);
                    }
                  ]);
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
        cameraOptions
      ]);
    } catch (ex) {
      _onChoose.completeError(ex);
    }
    return photo;
  }
}
