library triton_note.service.upload_session;

import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/model/photo.dart';
import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/report_session.dart';
import 'package:triton_note/service/server.dart';
import 'package:triton_note/service/reports.dart';

final _logger = new Logger('UploadSession');

class UploadSession {
  static const String filename = "user_data";

  static Future<String> upload(String url, Map<String, String> params, Blob photoData) async {
    _logger.fine("Uploading: ${url}: ${params}");
    final data = new FormData();
    params.forEach(data.append);
    data.appendBlob('file', photoData, filename);
    try {
      final req = await HttpRequest.request(url, method: 'POST', sendData: data);
      _logger.fine("Response of AWS S3: ${req.status}: ${req.responseText}");
      if (req.status < 200 || 300 <= req.status) throw new ServerError.fromRequest(req);
      return filename;
    } catch (ex) {
      if (ex is ProgressEvent && ex.target is HttpRequest) {
        throw new ServerError.fromRequest(ex.target);
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
  Future<Photo> get photo => _onUploaded.future;

  _upload(Blob photoData) async {
    try {
      final st = await session;
      final name = await upload(st.uploadUrl, st.uploadParams, photoData);
      final photo = await Server.photo(st.token, name);
      _onUploaded.complete(photo);
    } catch (ex) {
      _logger.fine("Failed to upload file: ${ex}");
      _onUploaded.completeError(ex);
    }
  }

  Future<SessionInference> infer(GeoInfo geoinfo, DateTime date) async {
    if (_onInferred == null) {
      _onInferred = new Completer<SessionInference>();
      try {
        await _onUploaded.future;
        final inf = await Server.infer((await session).token, geoinfo, date);
        _onInferred.complete(inf);
      } catch (ex) {
        _logger.fine("Failed to infer: ${ex}");
        _onInferred.completeError(ex);
      }
    }
    return _onInferred.future;
  }

  Future<Null> submit(Report report) async {
    await _onUploaded.future;
    Reports.add(await Server.submit((await session).token, report));
  }
}
