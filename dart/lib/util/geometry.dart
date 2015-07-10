library triton_note.util.geometry;

import 'dart:html';

import 'package:logging/logging.dart';

final _logger = new Logger('Geometry');

class Size {
  final double width;
  final double height;

  Size(this.width, this.height);
  factory Size.fromRect(Rectangle rect) => new Size(rect.width.toDouble(), rect.height.toDouble());

  Size putInto(Size other) {
    rate(Size s) => s.width / s.height;
    if (rate(this) < rate(other)) {
      return scale(other.height / height);
    } else {
      return scale(other.width / width);
    }
  }

  @override
  String toString() => "Size(${width}, ${height})";

  Size scale(double rate) => new Size(width * rate, height * rate);
}

class Alignment {
  static const CENTER = const Alignment(0.5);
  static const BEGIN = const Alignment(0.0);
  static const END = const Alignment(1.0);

  static horizontalByName(String v, [Alignment defValue = CENTER]) {
    switch (v) {
      case "left":
        return Alignment.BEGIN;
      case "right":
        return Alignment.END;
      case "center":
        return Alignment.CENTER;
      default:
        return defValue;
    }
  }
  static verticalByName(String v, [Alignment defValue = CENTER]) {
    switch (v) {
      case "bottom":
        return Alignment.BEGIN;
      case "top":
        return Alignment.END;
      case "center":
        return Alignment.CENTER;
      default:
        return defValue;
    }
  }

  final double rate;

  const Alignment(this.rate);

  double at(double base, double content) => (base - content) * rate;
}

class Alignment2d {
  final Alignment vertical, horizontal;

  const Alignment2d(this.horizontal, this.vertical);

  factory Alignment2d.fromName(String name) {
    final part = name.toLowerCase().split("-");

    if (part.length > 2) throw new ArgumentError("Illegal alignment name: ${name}");
    final h = Alignment.horizontalByName(part[0]);
    final v = Alignment.verticalByName(part.length == 2 ? part[1] : part[0]);
    return new Alignment2d(h, v);
  }

  Margin2d at(Size base, Size content) {
    final left = horizontal.at(base.width, content.width);
    final right = base.width - content.width - left;
    final bottom = vertical.at(base.height, content.height);
    final top = base.height - content.height - bottom;
    return new Margin2d(left, right, bottom, top);
  }
}

class Margin2d {
  final double left, right, bottom, top;

  const Margin2d(this.left, this.right, this.bottom, this.top);

  @override
  String toString() => "Margin(left: ${left}, right: ${right}, bottom: ${bottom}, top: ${top})";
}
