library triton_note.element.collapser;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:core_elements/core_collapse.dart';
import 'package:core_elements/core_animation.dart';

import 'package:triton_note/util/getter_setter.dart';

final _logger = new Logger('CollapserElement');

@Component(
    selector: 'collapser',
    templateUrl: 'packages/triton_note/element/collapser.html',
    cssUrl: 'packages/triton_note/element/collapser.css',
    useShadowDom: true)
class CollapserElement extends ShadowRootAware {
  @NgOneWay('title') String title;

  ShadowRoot _root;
  Getter<CoreCollapse> _collapse;
  Getter<Element> _arrowIcon;

  @override
  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
    _collapse = new CachedValue(() => _root.querySelector('core-collapse'));
    _arrowIcon = new CachedValue(() => _root.querySelector('#toggle core-icon'));

    final content = _root.host.querySelector('div#content');
    if (content != null) {
      _logger.finer("Get host content: ${content}");
      _collapse.value.querySelector('div#content').replaceWith(content);
    }

    final header = _root.host.querySelector('div#header');
    if (header != null) {
      _logger.finer("Get host header: ${header}");
      _root.querySelector('#toggle div#header').replaceWith(header);
    }
  }

  toggle() {
    _logger.finer("Toggle: ${_collapse.value}, icon: ${_arrowIcon.value}");
    final frames = [{'transform': "none"}, {'transform': "rotate(-90deg)"}];
    new CoreAnimation()
      ..target = _arrowIcon.value
      ..duration = _collapse.value.duration * 1000
      ..keyframes = _collapse.value.opened ? frames : frames.reversed.toList()
      ..fill = "both"
      ..play();
    _collapse.value.toggle();
  }
}
