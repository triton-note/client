library triton_note.util.chart;

import 'dart:html';

import 'package:js/js.dart';

@JS()
@anonymous
class Options {
  external bool get responsive;

  external factory Options({bool responsive});
}

@JS()
@anonymous
class DataSet {
  external String get label;
  external String get fillColor;
  external String get strokeColor;
  external String get pointColor;
  external String get pointStrokeColor;
  external String get pointHighlightFill;
  external String get pointHighlightStroke;

  external List<num> get data;

  external factory DataSet(
      {String label,
      String fillColor,
      String strokeColor,
      String pointColor,
      String pointStrokeColor,
      String pointHighlightFill,
      String pointHighlightStroke,
      List<num> data});
}

@JS()
@anonymous
class Data {
  external List get labels;
  external List<DataSet> get datasets;

  external factory Data({List<String> labels, List<DataSet> datasets});
}

@JS()
class Chart {
  external Chart(CanvasRenderingContext2D ctx);

  external dynamic Line(Data data, Options options);
}
