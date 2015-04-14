library report;

import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/model/photo.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/util/json_support.dart';

abstract class Report implements JsonSupport {
  String id;
  String userId;
  String comment;
  DateTime dateAt;
  Location location;
  Condition condition;
  Photo photo;
  List<Fishes> fishes;
  
  factory Report.fromJsonString(String text) => new _ReportImpl(JSON.decode(text));
  factory Report.fromMap(Map data) => new _ReportImpl(data);
}

class _ReportImpl implements Report {
  Map _data;
  
  _ReportImpl(this._data);
  
  Map toMap() => new Map.from(_data);
  
  String get id => _data['id'];
  set id(String v) => _data['id'] = v;

  String get userId => _data['userId'];
  set userId(String v) => _data['userId'] = v;

  String get comment => _data['comment'];
  set comment(String v) => _data['comment'] = v;
  
  /**
   * Convert epoch milliseconds to DateTime
   */
  DateTime get dateAt => (_data['dateAt'] == null) ? null : new DateTime.fromMillisecondsSinceEpoch(_data['dateAt']);
  set dateAt(DateTime v) => _data['dateAt'] = v.millisecondsSinceEpoch;
  
  /**
   * Convert Json to Location
   */
  Location get location => (_data['location'] == null) ? null : new Location.fromMap(_data['location']);
  set location(Location v) => _data['location'] = v.toMap();

  /**
   * Convert Json to Location
   */
  Condition get condition => (_data['condition'] == null) ? null : new Condition.fromMap(_data['condition']);
  set condition(Condition v) => _data['condition'] = v.toMap();
  
  /**
   * Convert Json to Photo
   */
  Photo get photo => (_data['photo'] == null) ? null : new Photo.fromMap(_data['photo']);
  set photo(Photo v) => _data['photo'] = v.toMap();
  
  /**
   * Convert Json to List<Fishes>
   */
  List<Fishes> get fishes {
    if (_data['fishes'] == null) return null;
    else return _data['fishes'].map((fs) {
      return new Fishes.fromMap(fs);
    }).toList();
  }
  set fishes(List<Fishes> v) => _data['fishes'] = v.map((a) => a.toMap());
}

abstract class Fishes implements JsonSupport {
  String name;
  int count;
  Weight weight;
  Length length;

  factory Fishes.fromJsonString(String text) => new _FishesImpl(JSON.decode(text));
  factory Fishes.fromMap(Map data) => new _FishesImpl(data);
}

class _FishesImpl implements Fishes {
  Map _data;
  
  _FishesImpl(this._data);
  
  Map toMap() => new Map.from(_data);

  String get name => _data['name'];
  set name(String v) => _data['name'] = v;

  int get count => _data['count'];
  set count(int v) => _data['count'] = v;

  Weight get weight => (_data['weight'] == null) ? null : new Weight.fromMap(_data['weight']);
  set weight(Weight v) => _data['weight'] = v.toMap();

  Length get length => (_data['length'] == null) ? null : new Length.fromMap(_data['length']);
  set length(Length v) => _data['length'] = v.toMap();
}
