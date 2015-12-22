library triton_note.util.file_reader;

import 'dart:async';
import 'dart:html';
import 'dart:js';
import 'dart:typed_data';

import 'package:logging/logging.dart';

final _logger = new Logger('FileReader');

Future<Blob> readAsBlob(String uri, [String type]) {
  _logger.finest(() => "Reading URI into Blob: ${uri}");
  final result = new Completer();

  context.callMethod('resolveLocalFileSystemURL', [
    uri,
    (entry) {
      _logger.finest(() => "Reading entry of uri: ${entry}");
      entry.callMethod('file', [
        (file) async {
          final list = await readAsList(file);
          final blob = new Blob([new Uint8List.fromList(list)], type);
          _logger.finest(() => "Read uri as blob: ${blob}(${blob.size})");
          result.complete(blob);
        },
        (error) {
          result.completeError("Failed to get file of uri: ${error}");
        }
      ]);
    },
    (error) {
      result.completeError("Failed to read uri: ${error}");
    }
  ]);

  return result.future;
}

Future<List<int>> readAsList(Blob blob) async {
  _logger.finest(() => "Reading Blob into List: ${blob}");

  final arrayBuffer = await fileReader_readAsArrayBuffer(blob);
  _logger.finest(() => "Converting to List<int>: ${arrayBuffer}");
  final uint8 = new JsObject(context['Uint8Array'], [arrayBuffer]);
  final list = new List<int>.generate(uint8['length'], (index) => uint8[index]);
  _logger.finest(() => "Read blob data: ${list.length}");
  return list;
}

Future<JsObject> fileReader_readAsArrayBuffer(blob) {
  _logger.finest(() =>
      "Reading data from: ${blob}, JsObject?${blob is JsObject}, Blob?${(blob is JsObject)? blob.instanceof(context['Blob']):(blob is Blob)}");
  final result = new Completer();

  final reader = new JsObject(context['FileReader'], []);
  reader['onloadend'] = (event) {
    try {
      final arrayBuffer = reader['result'];
      _logger.finest(() => "Read data from blob: ${arrayBuffer['byteLength']}");
      result.complete(arrayBuffer);
    } catch (ex) {
      _logger.warning("Failed to read blob: ${ex}");
      result.completeError(ex);
    }
  };
  reader['onerror'] = (event) {
    final error = reader['error'];
    _logger.warning("Error read blob: ${error}");
    result.completeError(error);
  };
  reader.callMethod('readAsArrayBuffer', [blob]);

  return result.future;
}
