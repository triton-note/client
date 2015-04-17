library server_testrun;

import 'dart:async';
import 'dart:io';
import 'dart:convert';

main() {
  HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 8123).then((HttpServer server) {
    print('listening on localhost, port ${server.port}');
    server.listen((HttpRequest req) async {
      print("Request method: ${req.method}");

      req.response.headers
        ..add('Access-Control-Allow-Origin', '*')
        ..add('Access-Control-Allow-Headers', '*')
        ..add('Access-Control-Allow-Methods', 'GET, POST');
      try {
        final ans = await process(req);
        print("Response: ${ans}");
        req.response
          ..statusCode = HttpStatus.OK
          ..write(ans)
          ..close();
      } catch (ex) {
        req.response
          ..statusCode = HttpStatus.INTERNAL_SERVER_ERROR
          ..write("Internal server error: ${ex}")
          ..close();
      }
    }, onDone: () => print("Done processing request."), onError: (error) => print("Error on processing request: ${error}"));
  }).catchError((ex) => print("Server Error: ${ex}"));
}

Future<String> process(HttpRequest req) async {
  if (req.method == "POST") {
    Future<String> load() async {
      final result = new Completer();
      final builder = new BytesBuilder();
      req.listen((buffer) {
        builder.add(buffer);
      }, onDone: () {
        final text = UTF8.decode(builder.takeBytes());
        result.complete(text);
      });
      return result.future;
    }
    final text = await load();
    print("Request: ${text}");
    return JSON.encode(job(req.uri.path, JSON.decode(text)));
  } else {
    return "OK";
  }
}

job(String path, json) {
  print("Request to ${path}");

  if (path == "/") {
    final Map map = json;
    final name = map['name'];
    if (name == "A") {
      return {map['name']: map['userId']};
    } else if (name == "B") {
      return map['list'].map((v) => {'id': v}).toList();
    }
  } else if (path == "/json-map") {
    final Map map = json;
    final result = {};
    map.forEach((String nameId, name) {
      if (nameId.startsWith("name-")) {
        final id = nameId.substring(5);
        result[name] = map["value-${id}"];
      }
    });
    return result;
  } else if (path == "/json-list") {
    final List list = json;
    return list.map((String name) => {'id': name}).toList();
  }
}
