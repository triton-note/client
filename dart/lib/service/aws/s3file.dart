library triton_note.service.aws.s3file;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:logging/logging.dart';

import 'package:triton_note/settings.dart';

final _logger = new Logger('S3File');

String _stringify(JsObject obj) => context['JSON'].callMethod('stringify', [obj]);

class S3File {
  static final s3 = new JsObject(context['AWS']['S3'], []);

  static Future<String> url(String path) async {
    final result = new Completer();
    try {
      final bucket = (await Settings).s3Bucket;
      s3.callMethod('getSignedUrl', [
        "getObject",
        new JsObject.jsify({"Bucket": bucket, "Key": path, 'Expires': (await Settings).photo.urlTimeout.inSeconds}),
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

  static Future<String> read(String path,
      [String bucket = null, String accessKey = null, String secretKey = null]) async {
    final result = new Completer();
    try {
      final bucketName = bucket != null ? bucket : (await Settings).s3Bucket;
      final client = (accessKey == null || secretKey == null)
          ? s3
          : new JsObject(
              context['AWS']['S3'], [new JsObject.jsify({'accessKeyId': accessKey, 'secretAccessKey': secretKey})]);
      _logger.finest("Reading ${bucketName}/${path}");
      client.callMethod('getObject', [
        new JsObject.jsify({'Bucket': bucketName, 'Key': path}),
        (error, data) {
          if (error != null) {
            _logger.fine("Error on read object(${path}): ${error}");
            result.completeError(error);
          } else {
            _logger.finest(() => "Read object: ${_stringify(data)}");
            final body = data['Body'];
            final text = new String.fromCharCodes(body);
            result.complete(text);
          }
        }
      ]);
    } catch (ex) {
      _logger.fine("Failed to read object(${path}): ${ex}");
      result.completeError(ex);
    }
    return result.future;
  }

  static Future<Null> putObject(String path, Blob data) async {
    final result = new Completer();
    try {
      final bucket = (await Settings).s3Bucket;
      final params = {'Bucket': bucket, 'Key': path, 'Body': data};
      if (data.type != null) {
        params['ContentType'] = data.type;
      }
      _logger.finest(() => "putObject: ${params}");

      s3.callMethod('putObject', [
        new JsObject.jsify(params),
        (error, data) {
          if (error != null) {
            _logger.warning("Failed to put object: ${path}");
            result.completeError(error);
          } else {
            _logger.finer("Success to put object: ${path}");
            result.complete();
          }
        }
      ]);
    } catch (ex) {
      result.completeError(ex);
    }
    return result.future;
  }
}
