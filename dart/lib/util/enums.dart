library triton_note.util.enums;

String nameOfEnum(e) => e == null ? null : e.toString().split("\.").last;
enumByName(List values, String name) => name == null ? null : values.firstWhere((a) => nameOfEnum(a) == name);
