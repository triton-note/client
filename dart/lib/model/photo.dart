library photo;

import 'package:triton_note/model/_json_support.dart';
import 'package:triton_note/service/s3file.dart';

abstract class Photo implements JsonSupport {
  Image original;
  Image mainview;
  Image thumbnail;

  factory Photo.fromJsonString(String text) => new _PhotoImpl(JSON.decode(text));
  factory Photo.fromMap(Map data) => new _PhotoImpl(data);
}

class _PhotoImpl implements Photo {
  final Map _data;
  final CachedProp<Image> _original;
  final CachedProp<Image> _mainview;
  final CachedProp<Image> _thumbnail;

  _PhotoImpl(Map data)
      : _data = data,
        _original = new CachedProp<Image>(data, 'original', (map) => new Image.fromMap(map)),
        _mainview = new CachedProp<Image>(data, 'mainview', (map) => new Image.fromMap(map)),
        _thumbnail = new CachedProp<Image>(data, 'thumbnail', (map) => new Image.fromMap(map));

  Map toMap() => _data;

  Image get original => _original.value;
  set original(Image v) => _original.value = v;

  Image get mainview => _mainview.value;
  set mainview(Image v) => _mainview.value = v;

  Image get thumbnail => _thumbnail.value;
  set thumbnail(Image v) => _thumbnail.value = v;
}

abstract class Image implements JsonSupport {
  String path;
  String url;

  factory Image.fromJsonString(String text) => new _ImageImpl(JSON.decode(text));
  factory Image.fromMap(Map data) => new _ImageImpl(data);
}

class _ImageImpl implements Image {
  static const _urlLimit = const Duration(seconds: S3File.urlExpires / 2);
  DateTime _urlStamp;
  String _url;
  bool _isRefreshing;

  final Map _data;
  _ImageImpl(this._data);
  Map toMap() => _data;

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

  void _refreshUrl() {
    if (!_isRefreshing) {
      final diff = (_urlStamp == null) ? null : new DateTime.now().difference(_urlStamp);
      if (diff == null || diff.compareTo(_urlLimit) > 0) {
        print("Refresh url: timestamp difference: ${diff}");
        _isRefreshing = true;
        S3File.url(path).then((v) {
          url = v;
          _urlStamp = new DateTime.now();
          _isRefreshing = false;
        });
      }
    }
  }
}
