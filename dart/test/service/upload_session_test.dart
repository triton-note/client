library upload_session_test;

import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:unittest/unittest.dart';

import 'package:triton_note/service/upload_session.dart';

final String bucketName = "triton-note-test";

main() {
  test('post png', () async {
    final photoData = getPhoto();
    final params = makeParams();
    final result = await UploadSession.upload("https://${bucketName}.s3.amazonaws.com/", params, photoData);
    print("Done Uploading: ${result}");
  });
}

Blob getPhoto() {
  final raw = """
<BASE64 DATA>
""";
  final list = new Uint8List.fromList(CryptoUtils.base64StringToBytes(raw));
  return new Blob([list]);
}

Map<String, String> makeParams() {
  final accessKey = "<ACCESS_KEY>";
  final secretKey = "<SECRET_KEY>";
  final folder = "sample-cognito-user/photo/sample-report";
  final acl = "bucket-owner-full-control";
  final contentType = "image/png";
  final policy = CryptoUtils.bytesToBase64(UTF8.encode(JSON.encode({
    "expiration": new DateTime.fromMillisecondsSinceEpoch(new DateTime.now().millisecondsSinceEpoch + 5 * 60 * 1000).toUtc().toIso8601String(),
    "conditions": [
      {"bucket": bucketName},
      ["starts-with", "\$key", folder],
      {"acl": acl},
      {"Content-Type": contentType},
      ["content-length-range", 10, 1000 * 1000]
    ]
  })));
  final hmac = new HMAC(new SHA1(), UTF8.encode(secretKey));
  hmac.add(UTF8.encode(policy));
  final signature = CryptoUtils.bytesToBase64(hmac.close());
  return {"key": "${folder}/\${filename}", "AWSAccessKeyId": accessKey, "acl": acl, "policy": policy, "signature": signature, "Content-Type": contentType};
}
