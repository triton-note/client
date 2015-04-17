library server;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:triton_note/settings.dart';

class Server {
  static Future<String> post(String url, String mimeType, String content) async {
    final result = new Completer<String>();
    try {
      final req = await HttpRequest.request(url, method: 'POST', mimeType: mimeType, sendData: content);
      if (req.status == 200) {
        result.complete(req.responseText);
      } else {
        result.completeError("HttpRequest.response:${req.status}: ${req.responseText}");
      }
    } catch (event) {
      result.completeError("Failed to post to ${url}");
    }
    return result.future;
  }

  static Future json(String path, content, [int retry = 3]) async {
    try {
      final text = await post("${await Settings.serverUrl}/${path}", "application/json", JSON.encode(content));
      try {
        return JSON.decode(text);
      } catch (ex) {
        if (ex is FormatException) return text;
        else return null;
      }
    } catch (ex) {
      print("Retry(${retry}): ${ex}");
      if (retry < 1) throw ex;
      return new Future.delayed(new Duration(seconds: retry * 3), () {
        return json(path, content, retry - 1);
      });
    }
  }
}
