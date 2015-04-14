library report;

import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/model/photo.dart';
import 'package:triton_note/model/location.dart';

class Report {
  String id;
  String userId;
  String comment;
  DateTime dateAt;
  Location location;
  Condition condition;
  Photo photo;
  List<Fishes> fishes;
  
  Report(this.id, this.userId, this.comment, this.dateAt, this.location, this.condition, this.photo, this.fishes);
}

class Fishes {
  String name;
  int count;
  Weight weight;
  Length length;
  
  Fishes(this.name, this.count, this.weight, this.length);
}
