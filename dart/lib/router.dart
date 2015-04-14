library triton_note_routing;

import 'package:angular/angular.dart';

void getTritonNoteRouteInitializer(Router router, RouteViewFactory views) {
  views.configure({
    'reports-list': ngRoute(
        path: '/reports',
        viewHtml: '<reports-list></reports-list>'),
    'report': ngRoute(
        path: '/report/:reportId',
        mount: {
          'detail': ngRoute(
              path: '/view',
              viewHtml: '<report-detail></report-detail>'),
          'edit': ngRoute(
              path: '/edit',
              viewHtml: '<report-edit></report-edit>')
        }),
    'home': ngRoute(
        defaultRoute: true,
        enter: (RouteEnterEvent e) =>
            router.go('reports-list', {},
                replace: true))
  });
}
