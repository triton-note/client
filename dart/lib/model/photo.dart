library photo;

import 'dart:async';

import 'package:triton_note/util/json_support.dart';
import 'package:triton_note/service/s3file.dart';

abstract class Photo implements JsonSupport {
  Image original;
  Image mainview;
  Image thumbnail;

  factory Photo.fromJsonString(String text) => new _PhotoImpl(JSON.decode(text));
  factory Photo.fromMap(Map data) => new _PhotoImpl(data);
}

class _PhotoImpl implements Photo {
  Map _data;
  _PhotoImpl(this._data);
  Map toMap() => new Map.from(_data);

  Image get original => (_data['original'] == null) ? null : new Image.fromMap(_data['original']);
  set original(Image v) => _data['original'] = v.toMap();

  Image get mainview => (_data['mainview'] == null) ? null : new Image.fromMap(_data['mainview']);
  set mainview(Image v) => _data['mainview'] = v.toMap();

  Image get thumbnail => (_data['thumbnail'] == null) ? null : new Image.fromMap(_data['thumbnail']);
  set thumbnail(Image v) => _data['thumbnail'] = v.toMap();
}

abstract class Image implements JsonSupport {
  String path;
  Future<String> volatileUrl();

  factory Image.fromJsonString(String text) => new _ImageImpl(JSON.decode(text));
  factory Image.fromMap(Map data) => new _ImageImpl(data);
}

class _ImageImpl implements Image {
  static const _urlLimit = const Duration(seconds: S3File.urlExpires / 2);
  DateTime _urlStamp;
  String _url;

  Map _data;
  _ImageImpl(this._data);
  Map toMap() => new Map.from(_data);

  String get path => _data['path'];
  set path(String v) => _data['path'] = v;

  Future<String> volatileUrl() async {
    final diff = (_urlStamp == null) ? null : new DateTime.now().difference(_urlStamp);
    print("Url timestamp difference: ${diff}");
    if (diff == null || diff > _urlLimit) {
      _url = await S3File.url(path);
      _urlStamp = new DateTime.now();
    }
    return _url;
  }
}
