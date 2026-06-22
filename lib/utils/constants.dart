// lib/utils/constants.dart
//
// ─────────────────────────────────────────────────────────
//  Update ALL values marked ⚠️ VERIFY after running
//  ModelInspector.inspect() and checking printed output.
// ─────────────────────────────────────────────────────────

class ASLConstants {
  // ── TEMPORAL WINDOW ───────────────────────────────────
  /// Number of frames the model expects per inference.
  /// Confirmed by your team: 30 frames.
  static const int sequenceLength = 30;

  // ── LANDMARK CONFIGURATION ────────────────────────────
  /// ⚠️ VERIFY: Breakdown of the 147 landmark points.
  ///
  /// MediaPipe Holistic gives:
  ///   • Pose:      33 landmarks
  ///   • Left hand: 21 landmarks
  ///   • Right hand:21 landmarks
  ///   • Face mesh: 468 landmarks (usually excluded for ASL word-level)
  ///
  /// 33 + 21 + 21 = 75 landmarks  (no face)
  /// 33 + 21 + 21 + 468 = 543     (full holistic)
  ///
  /// 147 does NOT match standard MediaPipe subsets cleanly.
  /// POSSIBLE interpretations — confirm with your ML team:
  ///   a) 147 = 49 points × 3 coords (x,y,z) → flattened = 441 floats
  ///   b) 147 = custom subset of pose(33)+hand(21)+hand(21) = 75,
  ///            then ×3 coords = 225 floats, not 147
  ///   c) 147 is the FLATTENED feature count (e.g. 49 points × 3 = 147)
  ///      meaning 49 landmark points each with x,y,z
  ///
  /// Most likely: 147 = flattened coords (49 points × 3).
  /// We default to this. Verify tensor shape from ModelInspector.
  static const int landmarkPoints = 49;   // ⚠️ VERIFY
  static const int coordsPerPoint = 3;    // x, y, z
  static const int landmarkFlatSize = landmarkPoints * coordsPerPoint; // = 147

  // ── MODEL INPUT SHAPE ─────────────────────────────────
  /// ⚠️ VERIFY against ModelInspector output.
  /// Expected: [1, 30, 147] — batch=1, frames=30, features=147
  /// Could also be [1, 30, 49, 3] if model expects unflattened.
  static const List<int> inputShape = [1, sequenceLength, landmarkFlatSize];

  // ── QUANTIZATION PARAMS ───────────────────────────────
  /// ⚠️ VERIFY: Copy exact values from ModelInspector output.
  /// These are used to convert float landmarks → int8 for inference.
  static const double inputScale = 0.0078125;   // ⚠️ VERIFY
  static const int inputZeroPoint = 0;          // ⚠️ VERIFY
  static const double outputScale = 0.00390625; // ⚠️ VERIFY
  static const int outputZeroPoint = -128;      // ⚠️ VERIFY

  // ── OUTPUT ────────────────────────────────────────────
  /// ⚠️ VERIFY: num_classes from ModelInspector output tensor shape[1]
  static const int numClasses = 100; // ⚠️ VERIFY — update from model output shape

  // ── ASSETS ────────────────────────────────────────────
  static const String modelAssetPath = 'assets/model.tflite';
  static const String labelsAssetPath = 'assets/labels.txt';
}