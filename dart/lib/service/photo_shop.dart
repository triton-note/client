library triton_note.service.photo_shop;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:logging/logging.dart';
import 'package:image/image.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/util/cordova.dart';
import 'package:triton_note/util/dialog.dart' as Dialog;
import 'package:triton_note/util/file_reader.dart';

final _logger = new Logger('PhotoShop');

class PhotoShop {
  static const CONTENT_TYPE = 'image/jpeg';

  final Completer<Blob> _onChoose = new Completer();
  final Completer<String> _onGetUrl = new Completer();
  final Completer<GeoInfo> _onGetGeoinfo = new Completer();
  final Completer<DateTime> _onGetTimestamp = new Completer();

  PhotoShop(bool take) {
    photo.then((blob) {
      _makeUrl(blob);
      _readExif(blob);
    }).catchError((error) {
      _onGetUrl.completeError("No photo data");
      _onGetGeoinfo.completeError("No photo data");
      _onGetTimestamp.completeError("No photo data");
    });
    _photo(take);
  }

  Future<Blob> get photo => _onChoose.future;
  Future<String> get photoUrl => _onGetUrl.future;
  Future<GeoInfo> get geoinfo => _onGetGeoinfo.future;
  Future<DateTime> get timestamp => _onGetTimestamp.future;

  _makeUrl(Blob blob) {
    try {
      final String url = Url.createObjectUrlFromBlob(blob);
      _logger.fine("Url of blob => ${url}");
      _onGetUrl.complete(url);
    } catch (ex) {
      _logger.fine("Failed to create url: ${ex}");
      _onGetUrl.completeError(ex);
    }
  }

  _readExif(Blob blob) async {
    _logger.fine("Exif Loading on ${blob}");
    try {
      final array = await fileReader_readAsArrayBuffer(blob.slice(0, 128 * 1024));

      final exif = new JsObject(context['ExifReader'], []);
      exif.callMethod('load', [array]);

      get(String name) => exif.callMethod('getTagDescription', [name]);

      try {
        String text = get('DateTimeOriginal');
        if (text == null) text = get('DateTimeDigitized');
        if (text == null) text = get('DateTime');
        final a = text.split(' ').expand((e) => e.split(':')).map(int.parse).toList();
        _logger.fine("Exif: Timestamp: ${a}");
        final date = new DateTime(a[0], a[1], a[2], a[3], a[4], a[5]);
        _onGetTimestamp.complete(date);
      } catch (ex) {
        _logger.fine("Exif: Timestamp: Error: ${ex}");
        _onGetTimestamp.completeError(ex);
      }
      try {
        final double lat = get('GPSLatitude');
        final double lon = get('GPSLongitude');
        _logger.fine("Exif: GPS: latitude=${lat}, longitude=${lon}");
        if (lat != null && lon != null) {
          _onGetGeoinfo.complete(new GeoInfo.fromMap({'latitude': lat, 'longitude': lon}));
        } else {
          _onGetGeoinfo.completeError("Exif: GPS: Error: null value");
        }
      } catch (ex) {
        _logger.fine("Exif: GPS: Error: ${ex}");
        _onGetGeoinfo.completeError(ex);
      }
    } catch (ex) {
      _logger.fine("Exif: Error: ${ex}");
      _onGetTimestamp.completeError(ex);
      _onGetGeoinfo.completeError(ex);
    }
  }

  _photo(bool take) async {
    try {
      if (isCordova) {
        final params = {
          'correctOrientation': true,
          'mediaType': context['navigator']['camera']['MediaType']['PICTURE'],
          'encodingType': context['Camera']['EncodingType']['JPEG'],
          'destinationType': context['Camera']['DestinationType']['FILE_URI'],
          'sourceType': take
              ? context['Camera']['PictureSourceType']['CAMERA']
              : context['Camera']['PictureSourceType']['PHOTOLIBRARY']
        };
        context['navigator']['camera'].callMethod('getPicture', [
          (uri) async {
            try {
              final blob = await readAsBlob(uri, CONTENT_TYPE);
              _logger.fine(() => "Get photo data: ${blob}");
              _onChoose.complete(blob);
            } catch (ex) {
              _onChoose.completeError("Failed to read photo data: ${ex}");
            }
          },
          (error) {
            _logger.fine("Failed to get photo: ${error}");
            _onChoose.completeError(error);
          },
          new JsObject.jsify(params)
        ]);
      } else {
        final file = await Dialog.chooseFile();
        _onChoose.complete(file);
      }
    } catch (ex) {
      _logger.fine("Failed to get photo file: ${ex}");
      _onChoose.completeError(ex);
    }
  }

  Completer<Image> _original;
  Future<Blob> resize(int maxSize) async {
    if (_original == null) {
      _original = new Completer();
      try {
        final blob = await photo;
        _logger.finer(() => "Decoding photo data: ${blob}");
        final image = decodeImage(await readAsList(blob));
        _logger.finer(() => "Decoded photo image: ${image}");
        _original.complete(image);
      } catch (ex) {
        _logger.warning("Failed to decode photo image: ${ex}");
        _original.completeError(ex);
      }
    }
    final original = await _original.future;
    int width;
    if (original.width > original.height) {
      width = maxSize;
    } else {
      width = (original.width * maxSize / original.height).round();
    }
    _logger.finest(() => "Resizing photo image: ${width}");
    final resized = copyResize(original, width);
    final data = encodeJpg(resized);
    return new Blob([data], CONTENT_TYPE);
  }
}
