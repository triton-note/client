library server;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:triton_note/model/distributions.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/model/photo.dart';
import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/report_session.dart';
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/service/credential.dart' as Cred;
import 'package:triton_note/settings.dart';

class Server {
  static Future<String> post(String url, String mimeType, String content) async {
    final result = new Completer<String>();
    try {
      final req = await HttpRequest.request(url, method: 'POST', mimeType: mimeType, sendData: content);
      if (req.status == 200) {
        result.complete(req.responseText);
      } else {
        result.completeError(new ServerError.fromRequest(req));
      }
    } catch (event) {
      result.completeError("Failed to post to ${url}");
    }
    return result.future;
  }

  static Future json(String path, content, [int retry = 3]) async {
    try {
      final text = await post("${await Settings.serverUrl}/${path}", "application/json", JSON.encode(content));
      try {
        return JSON.decode(text);
      } catch (ex) {
        if (ex is FormatException) return text;
        else return null;
      }
    } catch (ex) {
      if (ex is ServerError) throw ex;

      print("Retry(${retry}): ${ex}");
      if (retry < 1) throw ex;
      return new Future.delayed(new Duration(seconds: retry * 3), () {
        return json(path, content, retry - 1);
      });
    }
  }

  static String _ticket;

  static Future _login() async {
    final identityId = await Cred.identityId;
    final logins = await Cred.logins;
    _ticket = await json("login", {'identityId': identityId, 'logins': logins});
    return _ticket;
  }

  static Future _withTicket(String path, Map content) async {
    content['ticket'] = (_ticket != null) ? _ticket : await _login();
    try {
      return json(path, content);
    } catch (ex) {
      if (ex is ServerError && ex.status == 400 && ex.message == "Ticket Expired") {
        _ticket = null;
        return _withTicket(path, content);
      } else throw ex;
    }
  }

  static Future _withSession(String path, String session, Map content) async {
    content['session'] = session;
    try {
      return json(path, content);
    } catch (ex) {
      if (ex is ServerError && ex.status == 400 && ex.message == "Session Expired") {
        throw new SessionExpired();
      } else throw ex;
    }
  }

  static Future<Null> connect(String service, String accessKey) async {
    await _withTicket("/account/connect/${service}", {'accessKey': accessKey});
    return null;
  }

  static Future<Null> disconnect(String service) async {
    await _withTicket("/account/disconnect/${service}", {});
    return null;
  }

  static Future<SessionToken> newSession() async {
    final Map map = await _withTicket("/report/new-session", {});
    return new SessionToken(map['session'], map['upload']['url'], map['upload']['params']);
  }

  static Future<SessionInference> infer(String session, GeoInfo geoinfo, DateTime date) async {
    final Map map = await _withSession("/report/infer", session, {'geoinfo': geoinfo.toMap(), 'date': date.millisecondsSinceEpoch});
    final list = map['fishes'].map((v) => new Fishes.fromMap(v)).toList();
    return new SessionInference(map['spotName'], list);
  }

  static Future<Photo> photo(String session, String name) async {
    final Map map = await _withSession("/report/photo", session, {'names': [name]});
    return new Photo.fromMap(map['url']);
  }

  static Future<String> submit(String session, Report report) async {
    final String id = await _withSession("/report/submit", session, {'report': report});
    return id;
  }

  static Future<Null> publishToFacebook(String reportId, String accessKey) async {
    await _withTicket("/report/publish/facebook", {'id': reportId, 'accessKey': accessKey});
    return null;
  }

  static Future<List<Report>> load(int count, [Report last = null]) async {
    final param = {'count': count};
    if (last != null) param['last'] = last;
    final List list = await _withTicket("/report/load", param);
    return list.map((v) => new Report.fromMap(v)).toList();
  }

  static Future<Report> read(String reportId) async {
    final Map map = await _withTicket("/report/read", {'id': reportId});
    return new Report.fromMap(map['report']);
  }

  static Future<Null> update(Report report) async {
    await _withTicket("/report/update", {'report': report});
    return null;
  }

  static Future<Null> remove(String reportId) async {
    await _withTicket("/report/remove", {'id': reportId});
    return null;
  }

  static Future<Measures> loadMeasures() async {
    final Map map = await _withTicket("/account/measures/load", {});
    return new Measures.fromMap(map);
  }

  static Future<Null> updateMeasures(Measures measures) async {
    await _withTicket("/account/measures/update", measures.toMap());
    return null;
  }

  static Future<List<Catch>> distributionMine() async {
    final List list = await _withTicket("/distribution/mine", {});
    return list.map((v) => new Catch.fromMap(v)).toList();
  }

  static Future<List<Catch>> distributionOthers() async {
    final List list = await _withTicket("/distribution/others", {});
    return list.map((v) => new Catch.fromMap(v)).toList();
  }

  static Future<List<Catch>> distributionNames() async {
    final List list = await _withTicket("/distribution/names", {});
    return list.map((v) => new NameCount.fromMap(v)).toList();
  }

  static Future<Condition> getConditions(DateTime date, GeoInfo geoinfo) async {
    final Map map = await _withTicket("/conditions/get", {"date": date, "geoinfo": geoinfo});
    return new Condition.fromMap(map);
  }
}

class ServerError {
  final int status;
  final String message;

  ServerError(this.status, this.message);
  factory ServerError.fromRequest(HttpRequest req) => new ServerError(req.status, req.responseText);
  
  @override
  String toString() => "ServerError(status:${status}): ${message}";
}

class SessionExpired {}
