library triton_note.service.aws.s3file;

import 'dart:async';
import 'dart:js';

import 'package:logging/logging.dart';

import 'package:triton_note/settings.dart';

final _logger = new Logger('S3File');

class S3File {
  static const urlExpires = 900;
  static final s3 = new JsObject(context['AWS']['S3'], []);

  static Future<String> url(String path) async {
    final result = new Completer();
    try {
      final bucket = await Settings.s3Bucket;
      s3.callMethod('getSignedUrl', [
        "getObject",
        new JsObject.jsify({"Bucket": bucket, "Key": path, 'Expires': urlExpires}),
        (error, String url) {
          if (error == null) {
            _logger.fine("S3File.url: ${path} => ${url}");
            result.complete(url);
          } else {
            _logger.fine("Failed to getSignedUrl: ${error}");
            result.completeError(error);
          }
        }
      ]);
    } catch (ex) {
      _logger.fine("Failed to call getObject of s3file: ${ex}");
      result.completeError(ex);
    }
    return result.future;
  }
}
