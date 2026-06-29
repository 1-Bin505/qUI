// lib/services/inference_service.dart
//
// VERIFIED from ModelInspector:
//   Input:  [1, 147, 30] float32  (landmarks × frames)
//   Output: [1, 100]     float32  (100 ASL word classes)
//   No quantization — model takes raw floats directly.

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/constants.dart';
import '../utils/preprocessor.dart';

class _InferenceInput {
  final Uint8List modelBytes;
  final Float32List landmarkSeq; // [30 * 147] = 4410 floats, frames-major
  final List<String> labels;

  _InferenceInput({
    required this.modelBytes,
    required this.landmarkSeq,
    required this.labels,
  });
}

class InferenceResult {
  final String label;
  final double confidence;
  final int classIndex;
  final List<double> allProbs;

  InferenceResult({
    required this.label,
    required this.confidence,
    required this.classIndex,
    required this.allProbs,
  });

  @override
  String toString() =>
      'InferenceResult(label: $label, '
      'confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
}

class InferenceService {
  Uint8List? _modelBytes;
  List<String> _labels = [];
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    final byteData = await rootBundle.load(ASLConstants.modelAssetPath);
    _modelBytes = byteData.buffer.asUint8List();

    final labelsStr = await rootBundle.loadString(ASLConstants.labelsAssetPath);
    _labels = labelsStr
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    print('[InferenceService] Loaded model (${_modelBytes!.length} bytes), '
        '${_labels.length} labels.');
    _initialized = true;
  }

  /// [landmarkSeq] = Float32List length 4410 (30 frames × 147 coords), frames-major.
  /// Internally transposed to [1, 147, 30] before inference.
  Future<InferenceResult> predict(Float32List landmarkSeq) async {
    assert(_initialized, 'Call initialize() first');
    return compute(_runInference,
        _InferenceInput(
          modelBytes: _modelBytes!,
          landmarkSeq: landmarkSeq,
          labels: _labels,
        ));
  }

  void dispose() {
    _modelBytes = null;
    _initialized = false;
  }
}

// ── Top-level isolate function ────────────────────────────

InferenceResult _runInference(_InferenceInput input) {
  final interpreter = Interpreter.fromBuffer(input.modelBytes);

  // Input is stored frames-major: [frame0_lm0..lm146, frame1_lm0..lm146, ...]
  // Model expects [1, 147, 30] — landmarks-major (transposed).
  // Transpose: output[lm][frame] = input[frame * 147 + lm]
  final seq  = ASLConstants.sequenceLength;   // 30
  final feat = ASLConstants.landmarkFlatSize; // 147

  final transposed = List.generate(1, (_) =>
    List.generate(feat, (lm) =>
      List.generate(seq, (frame) =>
        input.landmarkSeq[frame * feat + lm]
      )
    )
  );

  // Output buffer: [1, 100] float32
  final outputBuffer = List.generate(1, (_) => List.filled(ASLConstants.numClasses, 0.0));

  interpreter.run(transposed, outputBuffer);
  interpreter.close();

  // outputBuffer[0] = list of 100 float logits
  final logits = Float32List.fromList(outputBuffer[0].cast<double>());

  // Softmax → probabilities
  final probs = Preprocessor.softmax(logits);

  // Argmax → predicted class
  final classIdx = Preprocessor.argmax(probs);
  final confidence = probs[classIdx];
  final label = classIdx < input.labels.length
      ? input.labels[classIdx]
      : 'class_$classIdx';

  print('[Inference] → $label (${(confidence * 100).toStringAsFixed(1)}%)');

  return InferenceResult(
    label: label,
    confidence: confidence,
    classIndex: classIdx,
    allProbs: probs.toList(),
  );
}