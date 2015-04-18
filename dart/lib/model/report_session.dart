library report_session;

import 'package:triton_note/model/report.dart';

class SessionInference {
  final String spotName;
  final List<Fishes> fishes;

  SessionInference(this.spotName, this.fishes);
}

class SessionToken {
  final String token;
  final String uploadUrl;
  final String uploadParams;

  SessionToken(this.token, this.uploadUrl, this.uploadParams);
}

