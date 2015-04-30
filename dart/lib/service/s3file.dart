library s3file;

import 'dart:async';
import 'dart:js';

import 'package:triton_note/settings.dart';

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
            print("S3File.url: ${path} => ${url}");
            result.complete(url);
          } else {
            print("Failed to getSignedUrl: ${error}");
            result.completeError(error);
          }
        }
      ]);
    } catch (ex) {
      print("Failed to call getObject of s3file: ${ex}");
      result.completeError(ex);
    }
    return result.future;
  }
}
