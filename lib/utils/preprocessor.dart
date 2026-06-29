// lib/utils/preprocessor.dart
//
// Model is float32 — no quantization needed.
// Only utilities kept: softmax and argmax.

import 'dart:math' show exp;
import 'dart:typed_data';

class Preprocessor {
  /// Softmax: raw float logits → probability distribution
  static Float32List softmax(Float32List logits) {
    final maxVal = logits.reduce((a, b) => a > b ? a : b);
    final exps = logits.map((v) => exp(v - maxVal)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return Float32List.fromList(exps.map((e) => e / sum).toList());
  }

  /// Argmax — index of highest value
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
}