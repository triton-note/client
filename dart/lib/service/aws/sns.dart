library triton_note.service.aws.sns;

import 'dart:async';
import 'dart:js';

import 'package:logging/logging.dart';

import 'package:triton_note/settings.dart';

final _logger = new Logger('SNS');

String _stringify(JsObject obj) => context['JSON'].callMethod('stringify', [obj]);

class SNS {
  static Completer<String> _onInit = null;
  static Future<String> get endpointArn async => _onInit?.future;
  static Future<String> init() async {
    if (_onInit == null) {
      _onInit = new Completer();
      try {
        final reg = await _PushPlugin.init();
        final arn = await _registerEndpoint(reg);
        _onInit.complete(arn);
      } catch (ex) {
        _logger.warning(() => "Error on initilizing: ${ex}");
        _onInit.complete(null);
      }
    }
    return endpointArn;
  }

  static Future<String> _registerEndpoint(final String regId) async {
    final Completer<String> result = new Completer();

    final params = {'PlatformApplicationArn': (await Settings).snsPlatformArn, 'Token': regId};
    _logger.finest(() => "Creating Endpoint: ${params}");

    final sns = new JsObject(context['AWS']['SNS'], []);
    sns.callMethod('createPlatformEndpoint', [
      new JsObject.jsify(params),
      (error, data) {
        if (error != null) {
          _logger.warning(() => "Error on creating Endpoint: ${error}");
          result.completeError(error);
        } else {
          _logger.info(() => "Created Endpoint: ${_stringify(data)}");
          result.complete(data['EndpointArn']);
        }
      }
    ]);
    return result.future;
  }
}

class _PushPlugin {
  static Future<String> init() async {
    final Completer<String> onRegister = new Completer();
    final settings = await Settings;

    final googleId = settings.googleProjectNumber;
    final params = {
      "android": {"senderID": googleId},
      "ios": {"alert": "true", "badge": "true", "sound": "true"},
      "windows": {}
    };
    _logger.fine(() => "Initializing: ${params}");

    final push = context['PushNotification'].callMethod('init', [new JsObject.jsify(params)]);
    push.callMethod('on', [
      'registration',
      (data) {
        final regId = data['registrationId'];
        _logger.info(() => "Registration ID: ${regId}");
        onRegister.complete(regId);
      }
    ]);
    push.callMethod('on', [
      'notification',
      (data) {
        _logger.finest(() => "Received notification (raw): ${_stringify(data)}");
        final map = {
          "title": data['title'],
          "message": data['message'],
          "count": data['count'],
          "sound": data['sound'],
          "image": data['image'],
          "additionalData": data['additionalData']
        };
        _logger.info(() => "Received notification: ${map}");
      }
    ]);
    push.callMethod('on', [
      'error',
      (error) {
        _logger.warning(() => "Error on notification: ${error}");
        if (!onRegister.isCompleted) {
          onRegister.completeError(error);
        }
      }
    ]);
    return onRegister.future;
  }
}
