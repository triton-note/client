library triton_note.element.infinite_scroll;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';

import 'package:triton_note/util/pager.dart';

final _logger = new Logger('InfiniteScrollElement');

@Component(
    selector: 'infinite-scroll',
    templateUrl: 'packages/triton_note/element/infinite_scroll.html',
    cssUrl: 'packages/triton_note/element/infinite_scroll.css',
    useShadowDom: true)
class InfiniteScrollElement extends ShadowRootAware {
  @NgOneWay('page-size') String pageSize;
  @NgOneWay('pager') Pager pager;

  int get pageSizeValue => (pageSize == null || pageSize.isEmpty) ? 10 : int.parse(pageSize);

  ShadowRoot _root;
  Element _scroller, _spinnerDiv;

  @override
  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
    _scroller = _root.querySelector('div#scroller');
    _scroller.style.height = _root.host.style.height;

    final content = _root.host.querySelector('div#content');
    assert(content != null);
    _scroller.querySelector('div#content').replaceWith(content);

    _spinnerDiv = _scroller.querySelector('div#spinner');
    _scroller.onScroll.listen(onScroll);
  }

  void onScroll(event) {
    final bottom = _scroller.scrollTop + _scroller.clientHeight;
    final spinnerPos = _spinnerDiv.offsetTop - _scroller.offsetTop;
    if (spinnerPos < bottom) {
      if (pager.hasMore) {
        pager.more(pageSizeValue);
      }
    }
  }
}
