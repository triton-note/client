library upload_session;

import 'dart:async';
import 'dart:html';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/model/photo.dart';
import 'package:triton_note/model/report_session.dart';
import 'package:triton_note/service/server.dart';

class UploadSession {
  final String filename = "user-data";
  final Completer<SessionToken> _onSession = new Completer<SessionToken>();
  final Completer<Photo> _onUploaded = new Completer<Photo>();
  SessionInference _inference;

  UploadSession(Blob photoData) {
    Server.newSession().then(_onSession.complete);
    _upload(photoData);
  }

  Future<SessionToken> get session => _onSession.future;
  Future<Photo> get photoUrl => _onUploaded.future;

  _upload(Blob photoData) async {
    final us = await session;
    final data = new FormData();
    us.uploadParams.forEach((name, value) {
      data.append(name, value);
    });
    data.appendBlob('file', photoData, filename);
    HttpRequest.request(us.uploadUrl, method: 'POST', sendData: data).then((req) async {
      if (req.status == 200) {
        final photo = await Server.photo(us.token, filename);
        _onUploaded.complete(photo);
      } else {
        _onUploaded.completeError(new ServerError(req.status, req.responseText));
      }
    });
  }

  Future<SessionInference> infer(GeoInfo geoinfo, DateTime date) async {
    if (_inference == null) {
      _inference = await Server.infer((await session).token, geoinfo, date);
    }
    return _inference;
  }
}
