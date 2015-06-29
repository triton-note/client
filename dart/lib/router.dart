library triton_note.routing;

import 'package:angular/angular.dart';

void getTritonNoteRouteInitializer(Router router, RouteViewFactory views) {
  views.configure({
    'reports-list': ngRoute(path: '/reports', viewHtml: '<reports-list></reports-list>'),
    'add': ngRoute(path: '/add/:report', viewHtml: '<add-report></add-report>'),
    'map': ngRoute(path: '/map/:from/:editable/:report', viewHtml: '<map-view></map-view>'),
    'report': ngRoute(
        path: '/report/:reportId',
        mount: {
      'detail': ngRoute(path: '/detail', viewHtml: '<report-detail></report-detail>'),
      'edit': ngRoute(path: '/edit', viewHtml: '<report-edit></report-edit>')
    }),
    'home': ngRoute(defaultRoute: true, enter: (RouteEnterEvent e) => router.go('reports-list', {}, replace: true))
  });
}
