library json_support_test;

import 'package:unittest/unittest.dart';

import 'package:triton_note/model/_json_support.dart';
import 'package:triton_note/model/value_unit.dart';

main() {
  test('CachedProp cache', () {
    int count = 0;
    final data = {'a': 1};
    final prop = new CachedProp<int>(data, 'a', (v) {
      count++;
      return v;
    }, (v) => v);

    expect(count, 0);
    expect(prop.value, 1);
    expect(prop.value, 1);
    expect(count, 1);
  });
  test('CachedProp set', () {
    int count = 0;
    final data = {'a': 1};
    final prop = new CachedProp<int>(data, 'a', (v) {
      count++;
      return v;
    }, (v) => v);

    expect(count, 0);
    expect(prop.value, 1);
    prop.value = 2;
    expect(prop.value, 2);
    expect(count, 1);
  });

  test('serialize list', () {
    final obj = ['a', 'b', 'c', new Weight.kg(12.34)];
    final ser = encodeToJson(obj);
    expect(ser, JSON.encode(['a', 'b', 'c', {'unit': 'kg', 'value': 12.34}]));
  });

  test('serialize map', () {
    final obj = {'a': 1, 'weight': new Weight.kg(12.34)};
    final ser = encodeToJson(obj);
    expect(ser, JSON.encode({'a': 1, 'weight': {'unit': 'kg', 'value': 12.34}}));
  });

  test('serialize list in map', () {
    final obj = {'a': [1, 2], 'weight': [new Weight.kg(12.34)]};
    final ser = encodeToJson(obj);
    expect(ser, JSON.encode({'a': [1, 2], 'weight': [{'unit': 'kg', 'value': 12.34}]}));
  });
}
