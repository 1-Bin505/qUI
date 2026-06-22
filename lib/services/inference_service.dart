// lib/services/inference_service.dart
//
// Loads .tflite model, runs inference on a 30-frame landmark sequence,
// and returns the predicted ASL label + confidence.
//
// All heavy work (quantization + interpreter.run) is dispatched via
// Flutter's compute() so it never blocks the UI/camera thread.

import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/constants.dart';
import '../utils/preprocessor.dart';

// ── Isolate message types ─────────────────────────────────

class _InferenceInput {
  final Uint8List modelBytes;       // raw .tflite bytes
  final Float32List landmarkSeq;    // [30 * 147] float coords
  final List<String> labels;

  _InferenceInput({
    required this.modelBytes,
    required this.landmarkSeq,
    required this.labels,
  });
}

class InferenceResult {
  final String label;
  final double confidence;         // 0.0–1.0 after softmax
  final int classIndex;
  final List<double> allProbs;     // full softmax distribution

  InferenceResult({
    required this.label,
    required this.confidence,
    required this.classIndex,
    required this.allProbs,
  });

  @override
  String toString() =>
      'InferenceResult(label: $label, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
}

// ── Main service class ────────────────────────────────────

class InferenceService {
  Uint8List? _modelBytes;
  List<String> _labels = [];
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Load model bytes from assets
    final byteData = await rootBundle.load(ASLConstants.modelAssetPath);
    _modelBytes = byteData.buffer.asUint8List();

    // Load label list from assets/labels.txt
    // Format: one label per line, index = class index
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

  /// Run inference on a 30-frame landmark sequence.
  /// [landmarkSeq] = Float32List of length 30 * 147 = 4410
  ///
  /// Dispatched to a background isolate via compute() — safe to call
  /// from camera callback without blocking UI.
  Future<InferenceResult> predict(Float32List landmarkSeq) async {
    assert(_initialized, 'Call initialize() before predict()');
    assert(
      landmarkSeq.length ==
          ASLConstants.sequenceLength * ASLConstants.landmarkFlatSize,
      'landmarkSeq must have ${ASLConstants.sequenceLength * ASLConstants.landmarkFlatSize} elements',
    );

    final input = _InferenceInput(
      modelBytes: _modelBytes!,
      landmarkSeq: landmarkSeq,
      labels: _labels,
    );

    // Run entirely off the main isolate
    return compute(_runInference, input);
  }

  void dispose() {
    _modelBytes = null;
    _initialized = false;
  }
}

// ── Top-level isolate function ────────────────────────────
// Must be top-level (not a method) for compute() to serialize it.

InferenceResult _runInference(_InferenceInput input) {
  // 1. Create interpreter from raw bytes (works inside isolate)
  final interpreter = Interpreter.fromBuffer(input.modelBytes);

  // 2. Quantize Float32 landmarks → Int8
  final quantizedInput = Preprocessor.quantizeInput(input.landmarkSeq);

  // 3. Reshape into [1, 30, 147] as required by model
  //    tflite_flutter accepts nested List or reshaped buffers.
  //    We reshape manually into a 3D list.
  final inputTensor = _reshape(quantizedInput);

  // 4. Prepare output buffer: [1, num_classes] Int8
  final outputBuffer = List.generate(
    1,
    (_) => Int8List(ASLConstants.numClasses),
  );

  // 5. Run interpreter
  interpreter.run(inputTensor, outputBuffer);
  interpreter.close();

  // 6. Dequantize output Int8 → Float32 logits
  final logits = Preprocessor.dequantizeOutput(outputBuffer[0] as Int8List);

  // 7. Softmax → probabilities
  final probs = Preprocessor.softmax(logits);

  // 8. Argmax → predicted class
  final classIdx = Preprocessor.argmax(probs);
  final confidence = probs[classIdx];
  final label = classIdx < input.labels.length
      ? input.labels[classIdx]
      : 'unknown_$classIdx';

  return InferenceResult(
    label: label,
    confidence: confidence,
    classIndex: classIdx,
    allProbs: probs.toList(),
  );
}

/// Reshape flat Int8List [4410] → List<List<List<int>>> [1][30][147]
List<List<List<int>>> _reshape(Int8List flat) {
  final seq = ASLConstants.sequenceLength;   // 30
  final feat = ASLConstants.landmarkFlatSize; // 147

  return List.generate(1, (_) {
    return List.generate(seq, (f) {
      final start = f * feat;
      return flat.sublist(start, start + feat);
    });
  });
}