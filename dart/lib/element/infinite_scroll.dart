library triton_note.element.infinite_scroll;

import 'dart:async';
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
  static const moreDur = const Duration(milliseconds: 800);

  @NgAttr('page-size') String pageSize;
  Pager _pager;
  Pager get pager => _pager;
  @NgOneWay('pager') set pager(Pager v) {
    _pager = v;
    _logger.finest(() => "Set pager: ${v}");
    _onReady.future.then((_) => _checkMore());
  }

  Completer<Null> _onReady = new Completer();

  int get pageSizeValue => (pageSize == null || pageSize.isEmpty) ? 10 : int.parse(pageSize);

  ShadowRoot _root;
  Element _scroller, _spinnerDiv;
  Timer _moreTimer;

  @override
  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
    _scroller = _root.querySelector('div#scroller');
    _scroller.style.height = _root.host.style.height;

    final content = _root.host.querySelector('div#content');
    assert(content != null);
    _scroller.querySelector('div#content').replaceWith(content);

    _spinnerDiv = _scroller.querySelector('div#spinner');
    _scroller.onScroll.listen((event) => _checkMore());

    _onReady.complete();
  }

  void _checkMore() {
    if (pager == null) return;

    final bottom = _scroller.scrollTop + _scroller.clientHeight;
    final spinnerPos = _spinnerDiv.offsetTop - _scroller.offsetTop;

    _logger.finer(() => "Check more: ${pager.hasMore}, bottom=${bottom}, spinner pos=${spinnerPos}");
    if (spinnerPos <= bottom && pager.hasMore) {
      if (_moreTimer != null && _moreTimer.isActive) _moreTimer.cancel();
      _moreTimer = new Timer(moreDur, () {
        pager.more(pageSizeValue).then((list) {
          // spinner がスクロールの外に見えなくなるまで続ける
          _checkMore();
        });
      });
    }
  }
}
