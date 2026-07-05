// lib/services/asl_pipeline.dart
//
// ASLive — ASLPipeline service
// ==============================
// Encapsulates the camera → MediaPipe → TFLite inference loop.
// This stub file provides the API surface that translate_screen.dart
// and main.dart depend on. Replace the body with your actual
// ML pipeline (MediaPipe Holistic + TFLite model + sliding window).
//
// Public API used by the UI:
//   - initialize()           → async setup (camera + model loading)
//   - start() / stop()       → toggle frame capture loop
//   - dispose()              → release resources
//   - cameraController       → CameraController? for the CameraPreview widget
//   - bufferProgress         → double 0..1, fraction of the 30-frame window filled
//   - onResult               → callback that fires when a prediction is ready
//   - onError                → callback for error messages
//
// The original Flask backend (app1.py) processes frames at ~30 FPS,
// maintains a 30-frame deque, and runs prediction every 2 frames.
// Mirror that logic here using the camera package's image stream.

import 'package:camera/camera.dart';
import 'inference_service.dart';

class ASLPipeline {
  CameraController? _controller;
  bool _isRunning = false;
  int _frameCount = 0;
  static const int _maxFrames = 30;

  // ── Callbacks ──
  void Function(InferenceResult result)? onResult;
  void Function(String error)? onError;

  // ── Public getters ──
  CameraController? get cameraController => _controller;
  double get bufferProgress => (_frameCount / _maxFrames).clamp(0.0, 1.0);

  /// Initialize camera and load the TFLite model.
  /// Call this once in initState before start().
  Future<void> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        onError?.call('No cameras found on this device.');
        return;
      }

      // Prefer front-facing camera (facingMode: 'user' in the web app)
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium, // 640×480 equivalent
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();

      // TODO: Load your TFLite model here
      // e.g. await Interpreter.fromAsset('converted_model.tflite');
    } catch (e) {
      onError?.call('Pipeline init error: $e');
    }
  }

  /// Begin the real-time capture + inference loop.
  void start() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    _isRunning = true;
    _frameCount = 0;

    _controller!.startImageStream((CameraImage image) {
      if (!_isRunning) return;

      _frameCount = (_frameCount + 1).clamp(0, _maxFrames);

      // TODO: Extract landmarks with MediaPipe Holistic
      // TODO: Build feature vector (147-dim), append to sliding window
      // TODO: Every 2 frames, if buffer is full, run TFLite inference
      // TODO: Call onResult?.call(InferenceResult(label: word, confidence: conf))
    });
  }

  /// Stop the capture loop and clear the buffer.
  void stop() {
    _isRunning = false;
    _frameCount = 0;
    try {
      _controller?.stopImageStream();
    } catch (_) {
      // Stream may already be stopped
    }
  }

  /// Release all resources.
  void dispose() {
    stop();
    _controller?.dispose();
    _controller = null;
  }
}
