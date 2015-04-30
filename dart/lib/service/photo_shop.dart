library photo_shop;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/util/binary_data.dart';
import 'package:triton_note/util/cordova.dart';
import 'package:triton_note/util/dialog.dart' as Dialog;

class PhotoShop {
  final Completer<Blob> _onChoose = new Completer();
  final Completer<String> _onGetUrl = new Completer();
  final Completer<GeoInfo> _onGetGeoinfo = new Completer();
  final Completer<DateTime> _onGetTimestamp = new Completer();

  PhotoShop(bool take) {
    _makeUrl();
    _photo(take);
  }

  Future<Blob> get photo => _onChoose.future;
  Future<String> get photoUrl => _onGetUrl.future;
  Future<GeoInfo> get geoinfo => _onGetGeoinfo.future;
  Future<DateTime> get timestamp => _onGetTimestamp.future;

  _makeUrl() async {
    try {
      final String url = Url.createObjectUrlFromBlob(await photo);
      print("Url of blob: ${url}");
      _onGetUrl.complete(url);
    } catch (ex) {
      print("Failed to create url: ${ex}");
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

      get(String name) => exif.callMethod('getTagDescription', [name]);

      try {
        String text = get('DateTimeOriginal');
        if (text == null) text = get('DateTimeDigitized');
        if (text == null) text = get('DateTime');
        final a = text.split(' ').expand((e) => e.split(':')).map(int.parse).toList();
        print("Exif: Timestamp: ${a}");
        final date = new DateTime(a[0], a[1], a[2], a[3], a[4], a[5]);
        _onGetTimestamp.complete(date);
      } catch (ex) {
        print("Exif: Timestamp: Error: ${ex}");
        _onGetTimestamp.completeError(ex);
      }
      try {
        final double lat = get('GPSLatitude');
        final double lon = get('GPSLongitude');
        print("Exif: GPS: latitude=${lat}, longitude=${lon}");
        if (lat != null && lon != null) {
          _onGetGeoinfo.complete(new GeoInfo.fromMap({'latitude': lat, 'longitude': lon}));
        } else {
          _onGetGeoinfo.completeError("Exif: GPS: Error: null value");
        }
      } catch (ex) {
        print("Exif: GPS: Error: ${ex}");
        _onGetGeoinfo.completeError(ex);
      }
    } catch (ex) {
      print("Exif: Error: ${ex}");
      _onGetTimestamp.completeError(ex);
      _onGetGeoinfo.completeError(ex);
    }
  }

  _photoDevice(options) {
    try {
      print("Choosing photo: ${options}");
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
                          print("Failed to load file: ${ex}");
                          _onChoose.completeError(ex);
                        }
                      };
                      reader['onerror'] = (event) {
                        print("Error on loading file");
                        _onChoose.completeError(reader['error']);
                      };
                      reader.callMethod('readAsArrayBuffer', [file]);
                    }
                  ]);
                } catch (ex) {
                  print("Failed to extract file: ${ex}");
                  _onChoose.completeError(ex);
                }
              }
            ]);
          } catch (ex) {
            print("Failed to resolving file url: ${ex}");
            _onChoose.completeError(ex);
          }
        },
        (error) {
          print("Failed to getPicture: ${error}");
          _onChoose.completeError(error);
        },
        new JsObject.jsify(options)
      ]);
    } catch (ex) {
      print("Failed to choosing picture: ${ex}");
      _onChoose.completeError(ex);
    }
    return photo;
  }

  _photo(bool take) async {
    if (isCordova) {
      _photoDevice({
        'correctOrientation': true,
        'mediaType': context['navigator']['camera']['MediaType']['PICTURE'],
        'encodingType': context['Camera']['EncodingType']['JPEG'],
        'destinationType': context['Camera']['DestinationType']['FILE_URI'],
        'sourceType': take
            ? context['Camera']['PictureSourceType']['CAMERA']
            : context['Camera']['PictureSourceType']['PHOTOLIBRARY']
      });
    } else {
      final file = await Dialog.chooseFile();
      _onChoose.complete(file);
      final reader = new FileReader();
      reader.onLoad.listen((event) {
        _readExif(reader.result);
      });
      reader.readAsArrayBuffer(file);
    }
  }
}
