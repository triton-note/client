library triton_note.model.photo;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/service/aws/dynamodb.dart';
import 'package:triton_note/service/aws/s3file.dart';
import 'package:triton_note/settings.dart';

final _logger = new Logger('Photo');

class Photo {
  final Image original;
  final ReducedImages reduced;

  Photo(String id)
      : original = new Image(id, 'original'),
        reduced = new ReducedImages(id);
}

class ReducedImages {
  static const _PATH_REDUCED = 'reduced';

  final Image mainview;
  final Image thumbnail;

  ReducedImages(String id)
      : mainview = new Image(id, "${_PATH_REDUCED}/mainview"),
        thumbnail = new Image(id, "${_PATH_REDUCED}/thumbnail");
}

class Image {
  final String _reportId;
  final String relativePath;
  Duration _urlLimit;
  DateTime _urlStamp;
  String _url;
  bool _isRefreshing = false;

  Image(this._reportId, this.relativePath);

  Future<String> get storagePath =>
      DynamoDB.cognitoId.then((cognitoId) => "photo/${relativePath}/${cognitoId}/${_reportId}/photo_file.jpg");

  String get url {
    _refreshUrl();
    return _url;
  }
  set url(String v) {
    _url = v;
    _urlStamp = new DateTime.now();
  }

  _refreshUrl() {
    if (_urlLimit == null) Settings.then((s) {
      final v = s.photo.urlTimeout.inSeconds * 0.9;
      _urlLimit = new Duration(seconds: v.round());
    });
    _doRefresh() {
      _isRefreshing = true;
      storagePath.then((path) {
        S3File.url(path).then((v) {
          url = v;
        }).catchError((ex) {
          _logger.info("Failed to get url of s3file: ${ex}");
        }).whenComplete(() {
          _isRefreshing = false;
        });
      });
    }
    if (!_isRefreshing) {
      final diff = (_urlStamp == null) ? null : new DateTime.now().difference(_urlStamp);
      if (diff == null || (_urlLimit != null && _urlLimit < diff)) {
        _logger.info("Refresh url: timestamp difference: ${diff}");
        _doRefresh();
      }
    }
  }
}
