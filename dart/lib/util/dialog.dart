library dialog;

import 'dart:async';
import 'dart:html';

import 'package:paper_elements/paper_dialog.dart';

Future<File> chooseFile() async {
  final html = """
<paper-dialog id="fileChooser" heading="Choose file" transition="core-transition-center" backdrop autoCloseDisabled>
  <input type="file" id="fileInput"></input>
</paper-dialog>
""";
  document.body.appendHtml(html);
  final result = new Completer<File>();

  final fileChooser = document.querySelector("#fileChooser") as PaperDialog;
  final fileInput = document.querySelector("#fileInput") as InputElement;
  fileInput.onChange.listen((event) {
    final files = fileInput.files;
    if (files.length > 0) {
      result.complete(files[0]);
      fileChooser.toggle();
    }
  });
  print("Toggle dialog: ${fileChooser}");
  fileChooser.toggle();
  return result.future;
}
