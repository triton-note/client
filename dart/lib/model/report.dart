library triton_note.model.report;

import 'package:triton_note/model/_json_support.dart';
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/model/photo.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/service/aws/dynamodb.dart';

abstract class Report implements DBRecord<Report> {
  String comment;
  DateTime dateAt;
  Location location;
  Condition condition;
  final Photo photo;
  final List<Fishes> fishes;

  factory Report.fromMap(Map data) => new _ReportImpl(data, DynamoDB.createRandomKey(), new DateTime.now(), []);

  factory Report.fromData(Map data, String id, DateTime dateAt) => new _ReportImpl(data, id, dateAt, []);
}

class _ReportImpl implements Report {
  final Map _data;
  final Photo photo;
  final CachedProp<Location> _location;
  final CachedProp<Condition> _condition;

  _ReportImpl(Map data, String id, this.dateAt, this.fishes)
      : _data = data,
        this.id = id,
        photo = new Photo(id),
        _location = new CachedProp<Location>.forMap(data, 'location', (map) => new Location.fromMap(map)),
        _condition = new CachedProp<Condition>.forMap(data, 'condition', (map) => new Condition.fromMap(map));

  Map toMap() => new Map.from(_data);

  final String id;
  DateTime dateAt;

  String get comment => _data['comment'];
  set comment(String v) => _data['comment'] = v;

  Location get location => _location.value;
  set location(Location v) => _location.value = v;

  Condition get condition => _condition.value;
  set condition(Condition v) => _condition.value = v;

  final List<Fishes> fishes;

  @override
  String toString() => "${_data}, id=${id}, dateAt=${dateAt},  fishes=${fishes}";

  bool isNeedUpdate(Report other) {
    if (other is _ReportImpl) {
      return this._data.toString() != other._data.toString() || this.dateAt != other.dateAt;
    } else {
      throw "Unrecognized obj: ${other}";
    }
  }

  void update(Report other) {
    if (other is _ReportImpl) {
      this._data
        ..clear()
        ..addAll(other._data);
      this.dateAt = other.dateAt;
    } else {
      throw "Unrecognized obj: ${other}";
    }
  }

  Report clone() => new _ReportImpl(toMap(), id, dateAt, fishes.map((o) => o.clone()).toList());
}

abstract class Fishes implements DBRecord<Fishes> {
  String reportId;
  String name;
  int count;
  Weight weight;
  Length length;

  factory Fishes.fromMap(Map data) => new _FishesImpl(data, DynamoDB.createRandomKey(), null);

  factory Fishes.fromData(Map data, String id, String reportId) => new _FishesImpl(data, id, reportId);
}

class _FishesImpl implements Fishes {
  final Map _data;
  final CachedProp<Weight> _weight;
  final CachedProp<Length> _length;

  _FishesImpl(Map data, this.id, this.reportId)
      : _data = data,
        _weight = new CachedProp<Weight>.forValueUnit(data, 'weight', (value) => new Weight.standard(value)),
        _length = new CachedProp<Length>.forValueUnit(data, 'length', (value) => new Length.standard(value));

  Map toMap() => new Map.from(_data);

  final String id;
  String reportId;

  String get name => _data['name'];
  set name(String v) => _data['name'] = v;

  int get count => _data['count'];
  set count(int v) => _data['count'] = v;

  Weight get weight => _weight.value;
  set weight(Weight v) => _weight.value = v;

  Length get length => _length.value;
  set length(Length v) => _length.value = v;

  @override
  String toString() => "${_data}, id=${id}, reportId=${reportId}";

  bool isNeedUpdate(Fishes other) {
    if (other is _FishesImpl) {
      return this._data.toString() != other._data.toString() || this.reportId != other.reportId;
    } else {
      throw "Unrecognized obj: ${other}";
    }
  }

  void update(Fishes other) {
    if (other is _FishesImpl) {
      this._data
        ..clear()
        ..addAll(other._data);
      this.reportId = other.reportId;
    } else {
      throw "Unrecognized obj: ${other}";
    }
  }

  Fishes clone() => new _FishesImpl(toMap(), id, reportId);
}
