library dialog;

import 'dart:async';
import 'dart:html';

import 'package:paper_elements/paper_dialog.dart';

Future<File> chooseFile() {
  final result = new Completer<File>();

  final fileChooser = _appendDialog();
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
  print("Toggle dialog: ${fileChooser}");
  fileChooser.toggle();
  return result.future;
}

PaperDialog _appendDialog() {
  fileChooser() => document.querySelector("#fileChooser");
  final e = fileChooser();
  if (e != null) return e;

  document.body.appendHtml("""
<paper-dialog id="fileChooser" heading="Choose file" transition="core-transition-center" backdrop autoCloseDisabled>
  <input type="file" id="fileInput"></input>
</paper-dialog>
""");
  return fileChooser();
}
