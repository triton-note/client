library triton_note.model.report;

import 'package:triton_note/model/_json_support.dart';
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/model/photo.dart';
import 'package:triton_note/model/location.dart';

abstract class Report implements JsonSupport {
  String id;
  String userId;
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
  final CachedProp<DateTime> _dateAt;
  final CachedProp<Photo> _photo;
  final CachedProp<Location> _location;
  final CachedProp<Condition> _condition;
  final CachedProp<List<Fishes>> _fishes;

  _ReportImpl(Map data)
      : _data = data,
        _dateAt = new CachedProp<DateTime>(data, 'dateAt',
            (int v) => new DateTime.fromMillisecondsSinceEpoch(v, isUtc: true),
            (DateTime v) => v.toUtc().millisecondsSinceEpoch),
        _photo = new CachedProp<Photo>(data, 'photo', (Map map) => new Photo.fromMap(map)),
        _location = new CachedProp<Location>(data, 'location', (Map map) => new Location.fromMap(map)),
        _condition = new CachedProp<Condition>(data, 'condition', (Map map) => new Condition.fromMap(map)),
        _fishes = new CachedProp<List<Fishes>>(data, 'fishes',
            (List list) => list.map((fs) => new Fishes.fromMap(fs)).toList(),
            (List<Fishes> o) => o.map((a) => a.asMap).toList());

  Map get asMap => _data;

  String get id => _data['id'];
  set id(String v) => _data['id'] = v;

  String get userId => _data['userId'];
  set userId(String v) => _data['userId'] = v;

  String get comment => _data['comment'];
  set comment(String v) => _data['comment'] = v;

  DateTime get dateAt => _dateAt.value;
  set dateAt(DateTime v) => _dateAt.value = v;

  Location get location => _location.value;
  set location(Location v) => _location.value = v;

  Condition get condition => _condition.value;
  set condition(Condition v) => _condition.value = v;

  Photo get photo => _photo.value;
  set photo(Photo v) => _photo.value = v;

  List<Fishes> get fishes => _fishes.value;
  set fishes(List<Fishes> v) => _fishes.value = v;
}

abstract class Fishes implements JsonSupport {
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

  String get name => _data['name'];
  set name(String v) => _data['name'] = v;

  int get count => _data['count'];
  set count(int v) => _data['count'] = v;

  Weight get weight => _weight.value;
  set weight(Weight v) => _weight.value = v;

  Length get length => _length.value;
  set length(Length v) => _length.value = v;

  @override
  String toString() {
    final sizesList =
        [weight, length].where((a) => a != null && a.value != null && a.value > 0).map((a) => a.toString());
    final sizes = sizesList.isEmpty ? '' : " (${sizesList.join(', ')})";
    return "${name}${sizes} x ${count}";
  }
}
