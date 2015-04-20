library upload_session;

import 'dart:async';
import 'dart:html';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/model/photo.dart';
import 'package:triton_note/model/report_session.dart';
import 'package:triton_note/service/server.dart';

class UploadSession {
  static const String filename = "user_data";
  
  static Future<String> upload(String url, Map<String, String> params, Blob photoData) async {
    final data = new FormData();
    params.forEach(data.append);
    data.appendBlob('file', photoData, filename);
    try {
      final req = await HttpRequest.request(url, method: 'POST', sendData: data);
      print("Response of AWS S3: ${req.status}: ${req.responseText}");
      if (req.status < 200 || 300 <= req.status) throw new ServerError.fromRequest(req);
      return filename;
    } catch (ex) {
      if (ex is ProgressEvent && ex.target is HttpRequest) {
        final HttpRequest req = ex.target;
        throw new ServerError.fromRequest(req);
      } else throw ex;
    }
  }
  
  final Completer<SessionToken> _onSession = new Completer<SessionToken>();
  final Completer<Photo> _onUploaded = new Completer<Photo>();
  Completer<SessionInference> _onInferred;

  UploadSession(Blob photoData) {
    Server.newSession().then(_onSession.complete);
    _upload(photoData);
  }

  Future<SessionToken> get session => _onSession.future;
  Future<Photo> get photoUrl => _onUploaded.future;

  _upload(Blob photoData) async {
    try {
      final st = await session;
      final name = await upload(st.uploadUrl, st.uploadParams, photoData);
      final photo = await Server.photo(st.token, name);
      _onUploaded.complete(photo);
    } catch (ex) {
      _onUploaded.completeError(ex);
    }
  }

  Future<SessionInference> infer(GeoInfo geoinfo, DateTime date) async {
    if (_onInferred == null) {
      _onInferred = new Completer<SessionInference>(); 
      Server.infer((await session).token, geoinfo, date)
        ..then(_onInferred.complete)
        ..catchError(_onInferred.completeError);
    }
    return _onInferred.future;
  }
}
