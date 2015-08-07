library triton_note.model.report;

import 'package:triton_note/model/_json_support.dart';
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/model/photo.dart';
import 'package:triton_note/model/location.dart';

abstract class DBRecord implements JsonSupport {
  String id;
}

abstract class Report implements DBRecord {
  String comment;
  DateTime dateAt;
  Location location;
  Condition condition;
  Photo photo;
  List<Fishes> fishes;

  factory Report.fromMap(Map data) => new _ReportImpl(data);
}

class _ReportImpl extends JsonSupport implements Report {
  final Map _data;
  final CachedProp<Photo> _photo;
  final CachedProp<Location> _location;
  final CachedProp<Condition> _condition;

  _ReportImpl(Map data)
      : _data = data,
        _photo = new CachedProp<Photo>(data, 'photo', (map) => new Photo.fromMap(map)),
        _location = new CachedProp<Location>(data, 'location', (map) => new Location.fromMap(map)),
        _condition = new CachedProp<Condition>(data, 'condition', (map) => new Condition.fromMap(map));

  Map get asMap => _data;

  String id;
  DateTime dateAt;

  String get comment => _data['comment'];
  set comment(String v) => _data['comment'] = v;

  Location get location => _location.value;
  set location(Location v) => _location.value = v;

  Condition get condition => _condition.value;
  set condition(Condition v) => _condition.value = v;

  Photo get photo => _photo.value;
  set photo(Photo v) => _photo.value = v;

  List<Fishes> fishes;
}

abstract class Fishes implements DBRecord {
  String reportId;
  String name;
  int count;
  Weight weight;
  Length length;

  factory Fishes.fromMap(Map data) => new _FishesImpl(data);
}

class _FishesImpl extends JsonSupport implements Fishes {
  final Map _data;
  final CachedProp<Weight> _weight;
  final CachedProp<Length> _length;

  _FishesImpl(Map data)
      : _data = data,
        _weight = new CachedProp<Weight>(data, 'weight', (map) => new Weight.fromMap(map)),
        _length = new CachedProp<Length>(data, 'length', (map) => new Length.fromMap(map));

  Map get asMap => _data;

  String id;
  String reportId;

  String get name => _data['name'];
  set name(String v) => _data['name'] = v;

  int get count => _data['count'];
  set count(int v) => _data['count'] = v;

  Weight get weight => _weight.value;
  set weight(Weight v) => _weight.value = v;

  Length get length => _length.value;
  set length(Length v) => _length.value = v;
}
