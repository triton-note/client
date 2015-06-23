library reports_add_component;

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/photo.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/service/upload_session.dart';
import 'package:triton_note/service/photo_shop.dart';
import 'package:triton_note/service/geolocation.dart' as Geo;
import 'package:triton_note/util/main_frame.dart';

@Component(
    selector: 'add-report',
    templateUrl: 'packages/triton_note/component/add_report.html',
    cssUrl: 'packages/triton_note/component/add_report.css',
    useShadowDom: false)
class AddReportComponent extends MainFrame {
  final Completer<UploadSession> _onSession = new Completer();
  final Report report = new Report.fromMap({'location': {}, 'condition': {'weather': {}}});
  bool isReady = false;
  bool get isSubmitable => report.photo != null && report.photo.original != null;

  AddReportComponent(Router router, RouteProvider routeProvider) : super(router) {
    try {
      report.asParam = routeProvider.parameters['report'];
      isReady = true;
    } catch (ex) {
      print("Adding new report.");
    }
  }

  choosePhoto(bool take) => rippling(() {
    final shop = new PhotoShop(take);
    isReady = true;

    shop.photoUrl.then((url) {
      report.photo = new Photo.fromMap({'reduced': {'mainview': {'url': url}}});
    });

    shop.photo.then((photo) async {
      final session = new UploadSession(photo);
      _onSession.complete(session);

      session.photo.then((v) async {
        report.photo = v;
      });

      try {
        report.dateAt = await shop.timestamp;
      } catch (ex) {
        print("No Timestamp in Exif: ${ex}");
        report.dateAt = new DateTime.now();
      }

      try {
        report.location.geoinfo = await shop.geoinfo;
      } catch (ex) {
        print("No GeoInfo in Exif: ${ex}");
        try {
          report.location.geoinfo = await Geo.location();
        } catch (ex) {
          print("Failed to get current location: ${ex}");
          report.location.geoinfo = new GeoInfo.fromMap({'latitude': 0, 'longitude': 0});
        }
      }

      try {
        final inference = await session.infer(report.location.geoinfo, report.dateAt);
        if (inference != null) {
          if (inference.spotName != null && inference.spotName.length > 0) {
            report.location.name = inference.spotName;
          }
          if (inference.fishes != null && inference.fishes.length > 0) {
            if (report.fishes == null) report.fishes = inference.fishes;
            else report.fishes.addAll(inference.fishes);
          }
        }
      } catch (ex) {
        print("Failed to infer: ${ex}");
      }
    });
  });

  submit() => rippling(() async {
    (await _onSession.future).submit(report);
  });

  showMap() => rippling(() {
    if (report.location.geoinfo != null) {
      router.go('map', {'from': 'add', 'editable': true, 'report': report.asParam});
    }
  });
}
