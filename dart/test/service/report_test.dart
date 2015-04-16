library report_test;

import 'dart:convert';

import 'package:unittest/unittest.dart';

import 'package:triton_note/model/report.dart';
import 'package:triton_note/model/location.dart';
import 'package:triton_note/model/photo.dart';
import 'package:triton_note/model/value_unit.dart';
import 'package:triton_note/util/enums.dart';

main() {
  test('fromJson', () {
    final text = makeJson();
    final json = JSON.decode(text);
    final obj = new Report.fromJsonString(text);
    print("Loaded report: ${obj}");

    expect(obj.id, json['id']);
    expect(obj.userId, json['userId']);
    expect(obj.comment, json['comment']);

    expect(true, obj.dateAt is DateTime);
    expect(obj.dateAt, new DateTime.fromMillisecondsSinceEpoch(json['dateAt']));

    expect(true, obj.location is Location);
    expect(obj.location.name, json['location']['name']);

    expect(true, obj.location.geoinfo is GeoInfo);
    expect(obj.location.geoinfo.latitude, json['location']['geoinfo']['latitude']);
    expect(obj.location.geoinfo.longitude, json['location']['geoinfo']['longitude']);

    expect(true, obj.condition is Condition);
    expect(obj.condition.moon, json['condition']['moon']);

    expect(true, obj.condition.tide is Tide);
    expect(nameOfEnum(obj.condition.tide), json['condition']['tide']);

    expect(true, obj.condition.weather is Weather);
    expect(obj.condition.weather.nominal, json['condition']['weather']['nominal']);
    expect(obj.condition.weather.iconUrl, json['condition']['weather']['iconUrl']);

    expect(true, obj.condition.weather.temperature is Temperature);
    expect(obj.condition.weather.temperature.value, json['condition']['weather']['temperature']['value']);
    expect(nameOfEnum(obj.condition.weather.temperature.unit), json['condition']['weather']['temperature']['unit']);

    expect(true, obj.photo is Photo);
    expect(true, obj.photo.original is Image);
    expect(true, obj.photo.mainview is Image);
    expect(true, obj.photo.thumbnail is Image);
    expect(obj.photo.original.path, json['photo']['original']['path']);
    expect(obj.photo.mainview.path, json['photo']['mainview']['path']);
    expect(obj.photo.thumbnail.path, json['photo']['thumbnail']['path']);

    expect(true, obj.fishes is List);
    expect(obj.fishes.length, 2);

    expect(true, obj.fishes[0] is Fishes);
    expect(obj.fishes[0].name, json['fishes'][0]['name']);
    expect(obj.fishes[0].count, json['fishes'][0]['count']);

    expect(true, obj.fishes[0].weight is Weight);
    expect(obj.fishes[0].weight.value, json['fishes'][0]['weight']['value']);
    expect(nameOfEnum(obj.fishes[0].weight.unit), json['fishes'][0]['weight']['unit']);

    expect(true, obj.fishes[0].length is Length);
    expect(obj.fishes[0].length.value, json['fishes'][0]['length']['value']);
    expect(nameOfEnum(obj.fishes[0].length.unit), json['fishes'][0]['length']['unit']);

    expect(true, obj.fishes[1] is Fishes);
    expect(obj.fishes[1].name, json['fishes'][1]['name']);
    expect(obj.fishes[1].count, json['fishes'][1]['count']);

    expect(true, obj.fishes[1].weight is Weight);
    expect(obj.fishes[1].weight.value, json['fishes'][1]['weight']['value']);
    expect(nameOfEnum(obj.fishes[1].weight.unit), json['fishes'][1]['weight']['unit']);

    expect(true, obj.fishes[1].length is Length);
    expect(obj.fishes[1].length.value, json['fishes'][1]['length']['value']);
    expect(nameOfEnum(obj.fishes[1].length.unit), json['fishes'][1]['length']['unit']);
  });

  test('empty json', () {
    final obj = new Report.fromJsonString("{}");
    expect(obj.id, null);
    obj.id = "A";
    expect(obj.id, "A");
  });

  test('changeAttributes', () {
    final obj = new Report.fromJsonString(makeJson());
    final geoB = new GeoInfo.fromMap({"latitude": 20.0, "longitude": 30.0});
    obj.location.geoinfo = geoB;
    expect(obj.location.geoinfo.latitude, 20.0);
    expect(obj.location.geoinfo.longitude, 30.0);
    print("GeoInfo B: ${obj.location.geoinfo}");
  });

  test('toJson', () {
    final textA = makeJson();
    final obj = new Report.fromJsonString(textA);
    final textB = JSON.encode(obj.toMap());
    expect(textA, textB);
  });
}

String makeJson() {
  return JSON.encode({
    "id": "Sample",
    "userId": "user-A",
    "comment": "Hoge",
    "dateAt": 1425612155000,
    "location": {"name": "Stendal River", "geoinfo": {"latitude": 37.96949880415789, "longitude": 23.419293612241745}},
    "condition": {
      "moon": 15,
      "tide": "Flood",
      "weather": {"nominal": "Clouds", "iconUrl": "http://openweathermap.org/img/w/04n.png", "temperature": {"value": 14.5, "unit": "Cels"}}
    },
    "photo": {
      "original": {"path": "photo/original/7a5b4bfa350b3150dfee9428/user-photo"},
      "mainview": {"path": "photo/reduced/7a5b4bfa350b3150dfee9428/mainview"},
      "thumbnail": {"path": "photo/reduced/7a5b4bfa350b3150dfee9428/thumbnail"}
    },
    "fishes": [
      {"name": "flounder", "count": 2, "weight": {"value": 1.2, "unit": "kg"}, "length": {"value": 38.5, "unit": "cm"}},
      {"name": "snapper", "count": 1, "weight": {"value": 0.4, "unit": "pond"}, "length": {"value": 17.9, "unit": "inch"}}
    ]
  });
}
