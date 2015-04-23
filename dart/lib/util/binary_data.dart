library binary_data;

import 'dart:typed_data';
import 'dart:js';

Uint8List fromArrayBuffer(JsObject arrayBuffer) {
  print("Converting ${arrayBuffer}: length=${arrayBuffer['byteLength']}");
  if (!arrayBuffer.instanceof(context['ArrayBuffer'])) {
    throw new ArgumentError.value(arrayBuffer, 'arrayBuffer', 'Not instanceof ArrayBuffer');
  }
  final result = new Uint8List(arrayBuffer['byteLength']);
  final buf = new JsObject(context['Uint8Array'], [arrayBuffer]);
  for (var i = 0; i < buf['length']; i++) {
    result[i] = buf[i];
  };
  return result;
}
