library triton_note.element.choose_list;

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';
import 'package:paper_elements/paper_dropdown.dart';

import 'package:triton_note/util/getter_setter.dart';

final _logger = new Logger('ChooseListElement');

@Component(
    selector: 'choose-list',
    templateUrl: 'packages/triton_note/element/choose_list.html',
    cssUrl: 'packages/triton_note/element/choose_list.css',
    useShadowDom: true)
class ChooseListElement extends ShadowRootAware {
  @NgTwoWay('value') String value;
  @NgOneWay('list') List<String> list;

  ShadowRoot _root;
  Getter<PaperDropdown> _dropdown;

  @override
  void onShadowRoot(ShadowRoot sr) {
    _root = sr;
    _dropdown = new CachedValue(() => _root.querySelector('paper-dropdown'));
  }

  open() {
    _logger.finest("Open dropdown");
    _dropdown.value.open();
  }

  choose(String v) {
    _logger.finer("Choose: ${v}");
    value = v;
    _dropdown.value.close();
  }
}
