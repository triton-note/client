library triton_note;

import 'package:triton_note/router.dart';
import 'package:triton_note/element/fit_image.dart';
import 'package:triton_note/element/calendar.dart';
import 'package:triton_note/element/about_oclock.dart';
import 'package:triton_note/component/add_report.dart';
import 'package:triton_note/component/reports_list.dart';
import 'package:triton_note/component/map_view.dart';
import 'package:triton_note/decorator/listen_event.dart';
import 'package:triton_note/decorator/google_map.dart';
import 'package:triton_note/util/cordova.dart';
import 'package:triton_note/util/resource_url_resolver_cordova.dart';

import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

class AppModule extends Module {
  AppModule() {
    bind(FitImageElement);
    bind(CalendarElement);
    bind(AboutOclockElement);

    bind(AddReportComponent);
    bind(ReportsListComponent);
    bind(MapViewComponent);

    bind(ListenChangeValue);
    bind(GoogleMap);

    bind(RouteInitializerFn, toValue: getTritonNoteRouteInitializer);
    bind(NgRoutingUsePushState, toValue: new NgRoutingUsePushState.value(false));
    bind(ResourceResolverConfig, toValue: new ResourceResolverConfig.resolveRelativeUrls(false));
    bind(ResourceUrlResolver, toImplementation: ResourceUrlResolverCordova);
  }
}

void main() {
  Logger.root
    ..level = Level.FINEST
    ..onRecord.listen((LogRecord r) {
      print(r.message);
    });

  onDeviceReady((event) {
    initPolymer().then((zone) {
      zone.run(() {
        applicationFactory().addModule(new AppModule()).run();
      });
    });
  });
}
