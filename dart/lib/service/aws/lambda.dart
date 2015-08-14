library triton_note.service.aws.lambda;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:logging/logging.dart';

import 'package:triton_note/settings.dart';

final _logger = new Logger('Lambda');

class Lambda {
  static const retryLimit = 3;

  static final Lambda MOON = new Lambda(Settings.then((s) => s.lambda.moon));
  static final Lambda WEATHER = new Lambda(Settings.then((s) => s.lambda.weather));

  final Future<LambdaInfo> info;

  Lambda(this.info);

  Future<Map> call(Map<String, String> dataMap) async {
    final result = new Completer();

    final url = (await info).url;
    final apiKey = (await info).key;

    final name = url.split('/').last;
    retry(final int count) {
      if (0 < count) _logger.warning(() => "retry count: ${count}");
      final isRetryable = count < retryLimit;
      next([bool p = true]) => (error) {
        if (isRetryable && p) {
          retry(count + 1);
        } else {
          result.completeError(error);
        }
      };
      try {
        final req = new HttpRequest()
          ..open('POST', url)
          ..setRequestHeader('x-api-key', apiKey)
          ..setRequestHeader('Content-Type', 'application/json')
          ..send(JSON.encode(dataMap));

        req.onLoadEnd.listen((event) {
          final text = req.responseText;
          _logger.finest(() => "Response of ${name}: (Status:${req.status}) ${text}");
          if (req.status == 200) result.complete(JSON.decode(text));
        });
        req.onError.listen((event) {
          next(500 <= req.status && req.status < 600)(req.responseText);
        });
        req.onTimeout.listen((event) {
          next()(event);
        });
      } catch (ex) {
        next()(ex);
      }
    }
    retry(0);
    return result.future;
  }
}
