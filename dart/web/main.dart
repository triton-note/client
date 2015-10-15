library triton_note;

import 'dart:html';
import 'dart:js';

import 'package:triton_note/router.dart';
import 'package:triton_note/formatter/fish_formatter.dart';
import 'package:triton_note/formatter/temperature_formatter.dart';
import 'package:triton_note/formatter/tide_formatter.dart';
import 'package:triton_note/dialog/edit_fish.dart';
import 'package:triton_note/dialog/edit_timestamp.dart';
import 'package:triton_note/dialog/edit_tide.dart';
import 'package:triton_note/dialog/edit_weather.dart';
import 'package:triton_note/element/distributions_filter.dart';
import 'package:triton_note/element/fit_image.dart';
import 'package:triton_note/element/calendar.dart';
import 'package:triton_note/element/choose_list.dart';
import 'package:triton_note/element/collapser.dart';
import 'package:triton_note/element/expandable_gmap.dart';
import 'package:triton_note/element/expandable_text.dart';
import 'package:triton_note/element/num_input.dart';
import 'package:triton_note/element/infinite_scroll.dart';
import 'package:triton_note/page/add_report.dart';
import 'package:triton_note/page/reports_list.dart';
import 'package:triton_note/page/report_detail.dart';
import 'package:triton_note/page/preferences.dart';
import 'package:triton_note/page/distributions.dart';
import 'package:triton_note/util/fabric.dart';
import 'package:triton_note/util/cordova.dart';
import 'package:triton_note/util/resource_url_resolver_cordova.dart';

import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';
import 'package:angular/core_dom/static_keys.dart';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

class AppExceptionHandler extends ExceptionHandler {
  call(dynamic error, dynamic stack, [String reason = '']) {
    final list = ["$error", reason];
    FabricCrashlytics.crash(list.join("\n"));
  }
}

class AppModule extends Module {
  AppModule() {
    bind(FishFormatter);
    bind(TemperatureFormatter);
    bind(TideFormatter);

    bind(EditFishDialog);
    bind(EditTimestampDialog);
    bind(EditTideDialog);
    bind(EditWeatherDialog);

    bind(DistributionsFilterElement);
    bind(FitImageElement);
    bind(CalendarElement);
    bind(ChooseListElement);
    bind(CollapserElement);
    bind(ExpandableGMapElement);
    bind(ExpandableTextElement);
    bind(NumInputElement);
    bind(InfiniteScrollElement);

    bind(AddReportPage);
    bind(ReportsListPage);
    bind(ReportDetailPage);
    bind(PreferencesPage);
    bind(DistributionsPage);

    bind(RouteInitializerFn, toValue: getTritonNoteRouteInitializer);
    bind(NgRoutingUsePushState, toValue: new NgRoutingUsePushState.value(false));
    bind(ResourceResolverConfig, toValue: new ResourceResolverConfig.resolveRelativeUrls(false));
    bind(ResourceUrlResolver, toImplementation: ResourceUrlResolverCordova);

    bindByKey(EXCEPTION_HANDLER_KEY, toValue: new AppExceptionHandler());
  }
}

void main() {
  Logger.root
    ..level = Level.FINEST
    ..onRecord.listen((record) {
      if (isCordova) {
        FabricCrashlytics.log("${record}");
      } else {
        window.console.log("${record.time} ${record}");
      }
    });

  try {
    onDeviceReady((event) {
      try {
        initPolymer().then((zone) {
          zone.run(() {
            Polymer.onReady.then((_) {
              applicationFactory().addModule(new AppModule()).run();
            });
          });
        });
      } catch (ex) {
        FabricCrashlytics.crash("$ex");
      }
    });
  } catch (ex) {
    window.alert("Error ${ex}");
    FabricCrashlytics.crash("$ex");
  }
}
