library tiroton_note.formatter.tide;

import 'package:angular/angular.dart';

import 'package:triton_note/model/location.dart';
import 'package:triton_note/util/enums.dart';

@Formatter(name: 'tideFilter')
class TideFormatter {
  String call(Tide src) {
    return (src == null) ? null : nameOfEnum(src);
  }
}
