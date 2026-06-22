// lib/utils/preprocessor.dart
//
// Converts a Float32 landmark sequence → quantized Int8 tensor
// ready to feed into the TFLite interpreter.

import 'dart:math' show exp;
import 'dart:typed_data';
import 'constants.dart';

class Preprocessor {
  /// Takes a flat Float32List of shape [30 * 147] = [4410]
  /// and returns an Int8List for the interpreter.
  ///
  /// Quantization: quantized = clamp(round(float / scale) + zeroPoint, -128, 127)
  static Int8List quantizeInput(Float32List rawCoords) {
    assert(
      rawCoords.length ==
          ASLConstants.sequenceLength * ASLConstants.landmarkFlatSize,
      'Expected ${ASLConstants.sequenceLength * ASLConstants.landmarkFlatSize} '
      'floats, got ${rawCoords.length}',
    );

    final normalized = _normalizeCoords(rawCoords);
    final quantized = Int8List(rawCoords.length);
    final scale = ASLConstants.inputScale;
    final zeroPoint = ASLConstants.inputZeroPoint;

    for (int i = 0; i < normalized.length; i++) {
      final q = (normalized[i] / scale).round() + zeroPoint;
      quantized[i] = q.clamp(-128, 127);
    }
    return quantized;
  }

  /// Dequantize output: Int8 → Float32
  /// Formula: float = (int8 - zeroPoint) * scale
  static Float32List dequantizeOutput(Int8List rawOutput) {
    final floats = Float32List(rawOutput.length);
    final scale = ASLConstants.outputScale;
    final zeroPoint = ASLConstants.outputZeroPoint;
    for (int i = 0; i < rawOutput.length; i++) {
      floats[i] = (rawOutput[i] - zeroPoint) * scale;
    }
    return floats;
  }

  /// Softmax: logits → probability distribution
  static Float32List softmax(Float32List logits) {
    final maxVal = logits.reduce((a, b) => a > b ? a : b);
    final exps = logits.map((v) => exp(v - maxVal)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return Float32List.fromList(exps.map((e) => e / sum).toList());
  }

  /// Argmax — returns index of highest value
  static int argmax(Float32List values) {
    int maxIdx = 0;
    double maxVal = values[0];
    for (int i = 1; i < values.length; i++) {
      if (values[i] > maxVal) {
        maxVal = values[i];
        maxIdx = i;
      }
    }
    return maxIdx;
  }

  // ── Normalize landmarks ──────────────────────────────
  // MediaPipe x,y already [0,1]. z (depth) shifted from [-1,1] to [0,1].
  // ⚠️ VERIFY: remove if your model was trained on raw unscaled coords.
  static Float32List _normalizeCoords(Float32List coords) {
    final out = Float32List(coords.length);
    for (int i = 0; i < coords.length; i++) {
      if (i % 3 == 2) {
        out[i] = (coords[i].clamp(-1.0, 1.0) + 1.0) / 2.0; // z
      } else {
        out[i] = coords[i].clamp(0.0, 1.0); // x, y
      }
    }
    return out;
  }
}