// lib/utils/model_inspector.dart
//
// ─────────────────────────────────────────────────────────
//  STEP 1 — RUN THIS FIRST before anything else.
//  It reads your actual .tflite file and prints:
//    • Input tensor shape, dtype, quantization scale/zero-point
//    • Output tensor shape, dtype, quantization scale/zero-point
//
//  Call ModelInspector.inspect() from main() or a debug button,
//  read the printed output, then confirm/update the constants
//  in lib/utils/constants.dart before running inference.
// ─────────────────────────────────────────────────────────

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';

class ModelInspector {
  static Future<void> inspect() async {
    print('═══════════════════════════════════════════');
    print('  SignSpeak — TFLite Model Inspector');
    print('═══════════════════════════════════════════');

    // Load model bytes from assets
    final byteData = await rootBundle.load('assets/model.tflite');
    final modelBytes = byteData.buffer.asUint8List();

    final interpreter = Interpreter.fromBuffer(modelBytes);

    // ── INPUT TENSORS ──────────────────────────────
    print('\n📥 INPUT TENSORS (${interpreter.getInputTensors().length} total):');
    for (int i = 0; i < interpreter.getInputTensors().length; i++) {
      final t = interpreter.getInputTensor(i);
      print('  [$i] name    : ${t.name}');
      print('  [$i] shape   : ${t.shape}');
      print('  [$i] type    : ${t.type}');
      print('  [$i] scale   : ${t.params.scale}');
      print('  [$i] zeroPoint: ${t.params.zeroPoint}');
      print('');
    }

    // ── OUTPUT TENSORS ─────────────────────────────
    print('📤 OUTPUT TENSORS (${interpreter.getOutputTensors().length} total):');
    for (int i = 0; i < interpreter.getOutputTensors().length; i++) {
      final t = interpreter.getOutputTensor(i);
      print('  [$i] name    : ${t.name}');
      print('  [$i] shape   : ${t.shape}');
      print('  [$i] type    : ${t.type}');
      print('  [$i] scale   : ${t.params.scale}');
      print('  [$i] zeroPoint: ${t.params.zeroPoint}');
      print('');
    }

    print('═══════════════════════════════════════════');
    print('ACTION: Update lib/utils/constants.dart with');
    print('the shapes and quant params printed above.');
    print('═══════════════════════════════════════════');

    interpreter.close();
  }
}