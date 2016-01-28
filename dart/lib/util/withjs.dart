library triton_note.withjs;

import 'dart:js';

String stringify(obj) => context['JSON'].callMethod('stringify', [obj]);
