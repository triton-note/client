library triton_note.util.dialog;

import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';

import 'package:paper_elements/paper_dialog.dart';

final _logger = new Logger('Dialog');

Future<File> chooseFile() {
  final result = new Completer<File>();
  try {
    final fileChooser = document.querySelector("div#options #fileChooser") as PaperDialog;
    final fileInput = fileChooser.querySelector("#fileInput") as InputElement;
    final sub = fileInput.onChange.listen(null);
    sub.onData((event) {
      final files = fileInput.files;
      if (files.length > 0) {
        result.complete(files[0]);
        fileChooser.toggle();
        sub.cancel();
      }
    });
    _logger.fine("Toggle dialog: ${fileChooser}");
    fileChooser.toggle();
  } catch (ex) {
    result.completeError(ex);
  }
  return result.future;
}
