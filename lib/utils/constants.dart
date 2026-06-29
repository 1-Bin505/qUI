// lib/utils/constants.dart
// Updated from ModelInspector output — verified against real model file.

class ASLConstants {
  // ── TEMPORAL WINDOW ───────────────────────────────────
  static const int sequenceLength = 30;

  // ── LANDMARK CONFIGURATION ────────────────────────────
  static const int landmarkPoints = 49;
  static const int coordsPerPoint = 3;
  static const int landmarkFlatSize = landmarkPoints * coordsPerPoint; // 147

  // ── MODEL INPUT SHAPE ─────────────────────────────────
  // VERIFIED: [1, 147, 30] — landmarks first, then frames
  // NOT [1, 30, 147] — the axes are swapped vs original assumption
  static const List<int> inputShape = [1, landmarkFlatSize, sequenceLength];

  // ── QUANTIZATION ──────────────────────────────────────
  // VERIFIED: model is float32, NOT int8 quantized
  // scale=0.0, zeroPoint=0 — pass raw floats directly, no quantization needed
  static const bool isQuantized = false;

  // ── OUTPUT ────────────────────────────────────────────
  // VERIFIED: [1, 100] float32 — 100 classes
  static const int numClasses = 100;

  // ── ASSETS ────────────────────────────────────────────
  static const String modelAssetPath = 'assets/model.tflite';
  static const String labelsAssetPath = 'assets/labels.txt';
}