library triton_note.model.photo;

import 'package:logging/logging.dart';

import 'package:triton_note/model/_json_support.dart';
import 'package:triton_note/service/s3file.dart';

final _logger = new Logger('Photo');

abstract class Photo implements JsonSupport {
  Image original;
  ReducedImages reduced;

  factory Photo.fromMap(Map data) => new _PhotoImpl(data);
}

class _PhotoImpl extends JsonSupport implements Photo {
  final Map _data;
  final CachedProp<Image> _original;
  final CachedProp<ReducedImages> _reduced;

  _PhotoImpl(Map data)
      : _data = data,
        _original = new CachedProp<Image>(data, 'original', (map) => new Image.fromMap(map)),
        _reduced = new CachedProp<ReducedImages>(data, 'reduced', (map) => new ReducedImages.fromMap(map));

  Map get asMap => _data;

  Image get original => _original.value;
  set original(Image v) => _original.value = v;

  ReducedImages get reduced => _reduced.value;
  set reduced(ReducedImages v) => _reduced.value = v;
}

abstract class ReducedImages implements JsonSupport {
  Image mainview;
  Image thumbnail;

  factory ReducedImages.fromMap(Map data) => new _ReducedImagesImpl(data);
}

class _ReducedImagesImpl extends JsonSupport implements ReducedImages {
  final Map _data;
  final CachedProp<Image> _mainview;
  final CachedProp<Image> _thumbnail;

  _ReducedImagesImpl(Map data)
      : _data = data,
        _mainview = new CachedProp<Image>(data, 'mainview', (map) => new Image.fromMap(map)),
        _thumbnail = new CachedProp<Image>(data, 'thumbnail', (map) => new Image.fromMap(map));

  Map get asMap => _data;

  Image get mainview => _mainview.value;
  set mainview(Image v) => _mainview.value = v;

  Image get thumbnail => _thumbnail.value;
  set thumbnail(Image v) => _thumbnail.value = v;
}

abstract class Image implements JsonSupport {
  String path;
  String url;

  factory Image.fromMap(Map data) => new _ImageImpl(data);
}

class _ImageImpl extends JsonSupport implements Image {
  static final _urlLimit = new Duration(seconds: (S3File.urlExpires * 0.9).round());
  DateTime _urlStamp;
  String _url;
  bool _isRefreshing = false;

  final Map _data;
  _ImageImpl(this._data);
  Map get asMap => _data;

  String get path => _data['path'];
  set path(String v) => _data['path'] = v;

  String get url {
    if (path == null) return _data['url'];
    else {
      _refreshUrl();
      return _url;
    }
  }
  set url(String v) {
    if (path == null) _data['url'] = v;
    else {
      _url = v;
    }
  }

  _refreshUrl() {
    _doRefresh() async {
      _isRefreshing = true;
      try {
        url = await S3File.url(path);
        _urlStamp = new DateTime.now();
      } catch (ex) {
        _logger.info("Failed to get url of s3file: ${ex}");
      } finally {
        _isRefreshing = false;
      }
    }
    if (!_isRefreshing) {
      final diff = (_urlStamp == null) ? null : new DateTime.now().difference(_urlStamp);
      if (diff == null || diff.compareTo(_urlLimit) > 0) {
        _logger.info("Refresh url: timestamp difference: ${diff}");
        _doRefresh();
      }
    }
  }
}
