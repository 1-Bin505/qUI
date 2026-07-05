// lib/services/inference_service.dart
//
// ASLive — InferenceResult data class
// =====================================
// Minimal data transfer object returned by the ASL inference pipeline.
// The translate_screen uses this to display predictions on the overlay.
//
// This file is imported by asl_pipeline.dart and translate_screen.dart.
// Replace this stub with your actual inference service implementation.

class InferenceResult {
  final String label;
  final double confidence;

  const InferenceResult({
    required this.label,
    required this.confidence,
  });

  @override
  String toString() => 'InferenceResult(label: $label, confidence: ${confidence.toStringAsFixed(2)})';
}
