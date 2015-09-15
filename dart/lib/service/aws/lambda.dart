library triton_note.service.aws.lambda;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:logging/logging.dart';

import 'package:triton_note/settings.dart';

final _logger = new Logger('Lambda');

typedef T _LoadResult<T>(Map map);

class Lambda<R> {
  static const retryLimit = 3;
  static const retryDur = const Duration(seconds: 30);

  final LambdaInfo info;
  final _LoadResult<R> _loader;

  Lambda(this.info, this._loader);

  Future<R> call(Map<String, String> dataMap) async {
    final result = new Completer<R>();

    final url = info.url;
    final apiKey = info.key;

    final name = url.split('/').last;
    retry(final int count) {
      final isRetryable = count < retryLimit;
      bool isRetring = false;
      next([bool p = true]) => (error) {
            if (!isRetring) {
              isRetring = true;
              if (isRetryable && p) {
                final next = count + 1;
                _logger.warning(() => "retring(${next}) after ${retryDur}");
                new Future.delayed(retryDur, () => retry(next));
              } else {
                result.completeError(error);
              }
            }
          };
      try {
        _logger.finest(() => "Posting to ${name}: ${url}");
        final req = new HttpRequest()
          ..open('POST', url)
          ..setRequestHeader('x-api-key', apiKey)
          ..setRequestHeader('Content-Type', 'application/json')
          ..send(JSON.encode(dataMap));

        req.onLoadEnd.listen((event) {
          final text = req.responseText;
          _logger.fine(() => "Response of ${name}(${url}): (Status:${req.status}) ${text}");
          if (req.status == 200) {
            try {
              final map = JSON.decode(text);
              final r = _loader(map);
              result.complete(r);
            } catch (ex) {
              next()(ex);
            }
          } else next(500 <= req.status && req.status < 600)(req.responseText);
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
