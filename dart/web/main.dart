library triton_note;

import 'dart:html';

import 'package:triton_note/router.dart';
import 'package:triton_note/dialog/edit_fish.dart';
import 'package:triton_note/dialog/edit_timestamp.dart';
import 'package:triton_note/element/fit_image.dart';
import 'package:triton_note/element/calendar.dart';
import 'package:triton_note/element/expandable_gmap.dart';
import 'package:triton_note/element/expandable_text.dart';
import 'package:triton_note/element/num_input.dart';
import 'package:triton_note/page/add_report.dart';
import 'package:triton_note/page/reports_list.dart';
import 'package:triton_note/page/report_detail.dart';
import 'package:triton_note/page/map_view.dart';
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
    bind(EditFishDialog);
    bind(EditTimestampDialog);

    bind(FitImageElement);
    bind(CalendarElement);
    bind(ExpandableGMapElement);
    bind(ExpandableTextElement);
    bind(NumInputElement);

    bind(AddReportPage);
    bind(ReportsListPage);
    bind(ReportDetailPage);
    bind(MapViewPage);

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
    ..onRecord.listen((record) {
      window.console.log(record.toString());
    });

  initPolymer().then((zone) => Polymer.onReady.then((_) {
    onDeviceReady((event) {
      applicationFactory().addModule(new AppModule()).run();
    });
  }));
}
