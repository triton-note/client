library s3file;

import 'dart:async';
import 'dart:js';

import 'package:triton_note/service/credential.dart';
import 'package:triton_note/settings.dart';

class S3File {
  static const photoNames = const ["original", "mainview", "thumbnail"];
  static final s3 = new JsObject(context['AWS']['S3'], []);

  static Future<Map<String, String>> load(String reportId) async {
    final bucket = await Settings.s3Bucket;
    final userId = await Credential.identityId;
    final folder = "${userId}/photo/${reportId}/";

    Future<String> url(String name) {
      final result = new Completer();
      try {
        s3.callMethod('getSignedUrl', [
          "getObject",
          new JsObject.jsify({"Bucket": bucket, "Key": "${folder}/${name}"}),
          (error, String url) {
            if (error == null) {
              result.complete(url);
            } else {
              result.completeError(error);
            }
          }
        ]);
      } catch (ex) {
        result.completeError(ex);
      }
      return result.future;
    }
    
    final map = {};
    photoNames.forEach((name) async {
      map[name] = await url(name);
    });
    return map;
  }
}
