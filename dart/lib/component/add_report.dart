library reports_add_component;

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:triton_note/model/report.dart';
import 'package:triton_note/service/upload_session.dart';
import 'package:triton_note/service/photo_shop.dart';
import 'package:triton_note/service/geolocation.dart' as Geo;
import 'package:triton_note/util/main_frame.dart';

@Component(selector: 'add-report', templateUrl: 'packages/triton_note/component/add_report.html')
class AddReportComponent extends MainFrame {
  final Completer<UploadSession> _onSession = new Completer();
  final PhotoShop _shop = new PhotoShop();
  final Report report = new Report.fromMap({});

  AddReportComponent(Router router) : super(router);
  
  choosePhoto() {
    _shop.choose();

    _shop.photoUrl.then((url) {
      report.photo = url;
    });

    _shop.photo.then((photo) async {
      final session = new UploadSession(photo);
      _onSession.complete(session);

      session.photoUrl.then((v) {
        report.photo = v;
      });

      final date = await _shop.timestamp;
      report.dateAt = (date != null) ? date : new DateTime.now();

      final info = await _shop.geoinfo;
      report.location.geoinfo = (info != null) ? info : await Geo.location();

      final inference = await session.infer(report.location.geoinfo, report.dateAt);
      report.location.name = inference.spotName;
      if (report.fishes == null) report.fishes = inference.fishes;
      else report.fishes.addAll(inference.fishes);
    });
  }

  submit() async {
    (await _onSession.future).submit(report);
  }
}
