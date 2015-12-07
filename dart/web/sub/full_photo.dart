library triton_note.full_photo;

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/application_factory.dart';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';

import 'package:triton_note/element/float_buttons.dart';

final _logger = new Logger('FullPhoto');

class AppModule extends Module {
  AppModule() {
    _logger.finest(() => "Initializing...");
    bind(FloatButtonsElement);
  }
}

@Injectable()
class FullPhoto {
  static String getUrl() {
    final q = window.location.search;
    if (q?.length > 2) {
      final url = Uri.decodeComponent(q.substring(1));
      _logger.finest(() => "Full photo url: ${url}");
      return url;
    } else {
      return null;
    }
  }

  final String url;

  FullPhoto() : url = getUrl();

  closeFullsize() {
    window.parent.dispatchEvent(new CustomEvent('FULLPHOTO_CLOSE'));
  }
}

void main() {
  Logger.root
    ..level = Level.FINEST
    ..onRecord.listen((record) {
      window.console.log("${record.time} ${record}");
    });

  initPolymer().then((zone) {
    zone.run(() {
      Polymer.onReady.then((_) {
        applicationFactory().rootContextType(FullPhoto).addModule(new AppModule()).run();
      });
    });
  });
}
