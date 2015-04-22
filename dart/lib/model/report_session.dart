library report_session;

import 'dart:collection';

import 'package:triton_note/model/report.dart';

class SessionInference {
  final String spotName;
  final List<Fishes> fishes;

  SessionInference(this.spotName, this.fishes);
}

class SessionToken {
  final String token;
  final String uploadUrl;
  final Map<String, String> uploadParams;

  SessionToken(this.token, this.uploadUrl, Map<String, String> map): uploadParams = new UnmodifiableMapView(map);
}

