library enums;

String nameOfEnum(e) => e.toString().split("\.").last;
enumByName(List values, String name) => values.firstWhere((a) => nameOfEnum(a) == name);
