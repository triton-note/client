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
            (map) => new DateTime.fromMillisecondsSinceEpoch(int.parse(map['N']), isUtc: true),
            (DateTime v) => {'N': v.toUtc().millisecondsSinceEpoch.toString()}),
        _photo = new CachedProp<Photo>(data, 'photo', (map) => new Photo.fromMap(map['M'])),
        _location = new CachedProp<Location>(data, 'location', (map) => new Location.fromMap(map['M'])),
        _condition = new CachedProp<Condition>(data, 'condition', (map) => new Condition.fromMap(map['M'])),
        _fishes = new CachedProp<List<Fishes>>(data, 'fishes',
            (map) => map['L'].map((fs) => new Fishes.fromMap(fs)).toList(),
            (List<Fishes> o) => {'L': o.map((a) => a.asMap).toList()});

  Map get asMap => _data;

  String get id => _data['id']['S'];
  set id(String v) => _data['id']['S'] = v;

  String get userId => _data['userId']['S'];
  set userId(String v) => _data['userId']['S'] = v;

  String get comment => _data['comment']['S'];
  set comment(String v) => _data['comment']['S'] = v;

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
        _weight = new CachedProp<Weight>(data, 'weight', (map) => new Weight.fromMap(map['M'])),
        _length = new CachedProp<Length>(data, 'length', (map) => new Length.fromMap(map['M']));

  Map get asMap => _data;

  String get name => _data['name']['S'];
  set name(String v) => _data['name']['S'] = v;

  int get count => int.parse(_data['count']['N']);
  set count(int v) => _data['count']['N'] = v.toString();

  Weight get weight => _weight.value;
  set weight(Weight v) => _weight.value = v;

  Length get length => _length.value;
  set length(Length v) => _length.value = v;
}
