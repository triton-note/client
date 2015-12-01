library triton_note.model.photo;

import 'dart:async';

import 'package:logging/logging.dart';

import 'package:triton_note/service/aws/cognito.dart';
import 'package:triton_note/service/aws/s3file.dart';
import 'package:triton_note/settings.dart';

final _logger = new Logger('Photo');

class Photo {
  static Future<Null> moveCognitoId(String previous, String current) async {
    final waiters = [ReducedImages.PATH_ORIGINAL, ReducedImages.PATH_MAINVIEW, ReducedImages.PATH_THUMBNAIL]
        .map((relativePath) async {
      final prefix = "photo/${relativePath}/${previous}/";
      final next = "photo/${relativePath}/${current}/";
      _logger.finest(() => "Moving cognito id: ${prefix} -> ${next}");

      final dones = (await S3File.list(prefix)).map((src) {
        final dst = "${next}${src.substring(prefix.length)}";
        S3File.copy(src, dst);
      });
      return Future.wait(dones);
    });
    await Future.wait(waiters);
  }

  final Image original;
  final ReducedImages reduced;

  Photo(String id)
      : original = new Image(id, ReducedImages.PATH_ORIGINAL),
        reduced = new ReducedImages(id);
}

class ReducedImages {
  static const _PATH_REDUCED = 'reduced';

  static const PATH_ORIGINAL = 'original';
  static const PATH_MAINVIEW = "${_PATH_REDUCED}/mainview";
  static const PATH_THUMBNAIL = "${_PATH_REDUCED}/thumbnail";

  final Image mainview;
  final Image thumbnail;

  ReducedImages(String id)
      : mainview = new Image(id, PATH_MAINVIEW),
        thumbnail = new Image(id, PATH_THUMBNAIL);
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

  Future<String> get storagePath async => "photo/${relativePath}/${await cognitoId}/${_reportId}/photo_file.jpg";

  Future<String> makeUrl() async => S3File.url(await storagePath);

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
        try {
          url = await makeUrl();
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
