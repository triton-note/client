library triton_note.element.choose_list;

import 'package:angular/angular.dart';
import 'package:logging/logging.dart';

final _logger = new Logger('ChooseListElement');

@Component(
    selector: 'choose-list',
    templateUrl: 'packages/triton_note/element/choose_list.html',
    cssUrl: 'packages/triton_note/element/choose_list.css',
    useShadowDom: true)
class ChooseListElement {
  @NgTwoWay('value') String value;
  @NgOneWay('list') List<String> list;
}
