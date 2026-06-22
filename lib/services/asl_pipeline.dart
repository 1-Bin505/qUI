// lib/services/asl_pipeline.dart
//
// Orchestrates: Camera → LandmarkService → FrameBuffer → InferenceService → label

import 'package:camera/camera.dart';
import '../models/frame_buffer.dart';
import '../utils/constants.dart';
import 'landmark_service.dart';
import 'inference_service.dart';

typedef OnResultCallback = void Function(InferenceResult result);
typedef OnErrorCallback = void Function(String error);

class ASLPipeline {
  final LandmarkService _landmarkService = LandmarkService();
  final InferenceService _inferenceService = InferenceService();
  final FrameBuffer _frameBuffer = FrameBuffer();

  CameraController? _cameraController;
  bool _isRunning = false;
  bool _inferenceInProgress = false;
  LandmarkFrame? _lastFrame; // used for sliding window padding

  OnResultCallback? onResult;
  OnErrorCallback? onError;

  double get bufferProgress =>
      _frameBuffer.fillLevel / ASLConstants.sequenceLength;

  Future<void> initialize() async {
    await _landmarkService.initialize();
    await _inferenceService.initialize();

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      onError?.call('No cameras found on device.');
      return;
    }

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
  }

  void start() {
    if (_isRunning || _cameraController == null) return;
    _isRunning = true;
    _frameBuffer.clear();

    _cameraController!.startImageStream((CameraImage image) async {
      if (!_isRunning) return;

      final frame = await _landmarkService.extractFromFrame(image);
      if (frame == null) return;

      _lastFrame = frame;
      _frameBuffer.add(frame);

      if (_frameBuffer.isReady && !_inferenceInProgress) {
        _inferenceInProgress = true;
        try {
          final snapshot = _frameBuffer.snapshot;
          final result = await _inferenceService.predict(snapshot);
          onResult?.call(result);
        } catch (e) {
          onError?.call('Inference error: $e');
        } finally {
          _inferenceInProgress = false;
          // Slide window: advance by 10 frames using last known frame
          if (_lastFrame != null) {
            for (int i = 0; i < 10; i++) {
              _frameBuffer.add(_lastFrame!);
            }
          }
        }
      }
    });
  }

  void stop() {
    _isRunning = false;
    _cameraController?.stopImageStream();
    _frameBuffer.clear();
  }

  void dispose() {
    stop();
    _cameraController?.dispose();
    _landmarkService.dispose();
    _inferenceService.dispose();
  }

  CameraController? get cameraController => _cameraController;
  bool get isRunning => _isRunning;
}