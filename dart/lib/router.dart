library triton_note.routing;

import 'package:angular/angular.dart';

void getTritonNoteRouteInitializer(Router router, RouteViewFactory views) {
  views.configure({
    'reports-list': ngRoute(path: '/reports', viewHtml: '<reports-list></reports-list>'),
    'report-detail': ngRoute(path: '/report-detail/:reportId', viewHtml: '<report-detail></report-detail>'),
    'add': ngRoute(path: '/add', viewHtml: '<add-report></add-report>'),
    'preferences': ngRoute(path: '/preferences', viewHtml: '<preferences></preferences>'),
    'distributions': ngRoute(path: '/distributions', viewHtml: '<distributions></distributions>'),
    'experiment': ngRoute(path: '/experiment', viewHtml: '<experiment></experiment>'),
    'home': ngRoute(defaultRoute: true, enter: (RouteEnterEvent e) => router.go('reports-list', {}, replace: true))
  });
}
