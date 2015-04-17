library server_testrun;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:unittest/unittest.dart';

import 'package:triton_note/service/server.dart';
import 'package:triton_note/settings.dart';

final serverUrl = "http://localhost:8123";

main() {
  Settings.initialize({
    'serverUrl': serverUrl
  });
  
  test('post map', () async {
    if (await check) {
      final text = await Server.post(serverUrl, "text/json", JSON.encode({'name': 'A', 'userId': 'user-A'}));
      print("Response from server: ${text}");
      final Map ans = JSON.decode(text);

      expect(ans['A'], "user-A");
    }
  });

  test('post list', () async {
    if (await check) {
      final text = await Server.post(serverUrl, "text/json", JSON.encode({'name': 'B', 'list': ['X', 'Y', 'Z']}));
      print("Response from server: ${text}");
      final List ans = JSON.decode(text);

      expect(ans.length, 3);
      ans.forEach((Map v) => expect(v.length, 1));
      expect(ans[0]['id'], 'X');
      expect(ans[1]['id'], 'Y');
      expect(ans[2]['id'], 'Z');
    }
  });

  test('json map', () async {
    if (await check) {
      final Map ans = await Server.json("json-map", {'name-A': 'X', 'value-A': 1, 'name-B': 'Y', 'value-B': 2, 'name-C': 'Z', 'value-C': 3});
      print("Response from server: ${ans}");

      expect(ans.length, 3);
      expect(ans['X'], 1);
      expect(ans['Y'], 2);
      expect(ans['Z'], 3);
    }
  });

  test('json list', () async {
    if (await check) {
      final List ans = await Server.json("json-list", ['X', 'Y', 'Z']);
      print("Response from server: ${ans}");

      expect(ans.length, 3);
      ans.forEach((Map v) => expect(v.length, 1));
      expect(ans[0]['id'], 'X');
      expect(ans[1]['id'], 'Y');
      expect(ans[2]['id'], 'Z');
    }
  });

  test('straight', () async {
    if (await check) {
      final String ans = await Server.json("straight", {'name': 'ABC'});
      print("Response from server: ${ans}");

      expect(ans, "ABC");
    }
  });
}

Future<bool> get check async {
  try {
    final url = await Settings.serverUrl;
    return url == serverUrl && await HttpRequest.getString(serverUrl) == "OK";
  } catch (ex) {
    return false;
  }
}
