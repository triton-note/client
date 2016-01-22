library triton_note.element.choose_list;

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';

import 'package:triton_note/util/getter_setter.dart';

final _logger = new Logger('ChooseListElement');

@Component(
    selector: 'choose-list',
    templateUrl: 'packages/triton_note/element/choose_list.html',
    cssUrl: 'packages/triton_note/element/choose_list.css',
    useShadowDom: true)
class ChooseListElement {
  @NgOneWayOneTime('setter') set setter(Setter<ChooseListElement> v) => v?.value = this; // Optional
  @NgTwoWay('value') String value;
  @NgOneWay('list') List<String> list;
}
