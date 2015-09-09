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
  static const _localTimeout = const Duration(minutes: 10);
  static const _refreshInterval = const Duration(minutes: 1);

  final _IntervalKeeper _refresher = new _IntervalKeeper(_refreshInterval);
  final String _reportId;
  final String relativePath;
  DateTime _urlLimit;
  String _url;

  Image(this._reportId, this.relativePath);

  Future<String> get storagePath =>
      DynamoDB.cognitoId.then((cognitoId) => "photo/${relativePath}/${cognitoId}/${_reportId}/photo_file.jpg");

  String get url {
    _refreshUrl();
    return _url;
  }
  set url(String v) {
    _url = v;
    if (v.startsWith('http')) {
      Settings.then((s) {
        final v = s.photo.urlTimeout.inSeconds * 0.9;
        final dur = new Duration(seconds: v.round());
        _urlLimit = new DateTime.now().add(dur);
      });
    } else {
      _urlLimit = new DateTime.now().add(_localTimeout);
    }
  }

  _refreshUrl() {
    if (_url == null || (_urlLimit != null && _urlLimit.isBefore(new DateTime.now()))) {
      _refresher.go(() async {
        final path = await storagePath;
        _logger.info("Refresh url of s3file: ${path}");
        try {
          url = await S3File.url(path);
        } catch (ex) {
          _logger.info("Failed to get url of s3file: ${ex}");
        }
      });
    }
  }
}

class _IntervalKeeper {
  final Duration interval;
  DateTime _limit;
  bool _isGoing = false;

  _IntervalKeeper(this.interval);

  bool get canGo => !_isGoing && (_limit == null || _limit.isBefore(new DateTime.now()));

  go(Future something()) async {
    if (canGo) {
      _isGoing = true;
      try {
        await something();
      } finally {
        _isGoing = false;
        _limit = new DateTime.now().add(interval);
      }
    }
  }
}
