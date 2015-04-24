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
  final Report report = new Report.fromMap({'location': {}, 'condition': {'weather': {}}});
  String photoUrl;

  AddReportComponent(Router router) : super(router);

  choosePhoto() {
    _shop.choose();

    _shop.photoUrl.then((url) {
      photoUrl = url;
    });

    _shop.photo.then((photo) async {
      final session = new UploadSession(photo);
      _onSession.complete(session);

      session.photoUrl.then((v) async {
        report.photo = v;
        photoUrl = await v.mainview.volatileUrl();
      });

      final date = await _shop.timestamp;
      if (date != null) {
        report.dateAt = date;
      } else {
        print("No Timestamp in Exif. Get current time");
        report.dateAt = new DateTime.now();
      }

      final info = await _shop.geoinfo;
      if (info != null) {
        report.location.geoinfo = info;
      } else {
        print("No GeoInfo in Exif. Get current location");
        report.location.geoinfo = await Geo.location();
      }

      final inference = await session.infer(report.location.geoinfo, report.dateAt);
      if (inference != null) {
        if (inference.spotName != null) report.location.name = inference.spotName;
        if (inference.fishes != null && inference.fishes.length > 0) {
          if (report.fishes == null) report.fishes = inference.fishes;
          else report.fishes.addAll(inference.fishes);
        }
      }
    });
  }

  submit() async {
    (await _onSession.future).submit(report);
  }
}
