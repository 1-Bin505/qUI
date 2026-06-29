import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
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
  CameraDescription? _camera;
  bool _isRunning = false;
  bool _inferenceInProgress = false;
  LandmarkFrame? _lastFrame;

  OnResultCallback? onResult;
  OnErrorCallback? onError;

  double get bufferProgress =>
      _frameBuffer.fillLevel / ASLConstants.sequenceLength;

  Future<void> initialize() async {
    await _landmarkService.initialize();
    await _inferenceService.initialize();

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      onError?.call('No cameras found.');
      return;
    }

    // Front camera for self-facing signing
    _camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      _camera!,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21, // required for MLKit on Android
    );

    await _cameraController!.initialize();
    print('[ASLPipeline] Initialized with ${_camera!.lensDirection} camera.');
  }

  void start() {
    if (_isRunning || _cameraController == null) return;
    _isRunning = true;
    _frameBuffer.clear();

    _cameraController!.startImageStream((CameraImage image) async {
      if (!_isRunning) return;

      final orientation = _cameraController!.value.deviceOrientation;

      final frame = await _landmarkService.extractFromFrame(
        image,
        _camera!,
        orientation,
      );

      if (frame == null) return; // no pose detected

      _lastFrame = frame;
      _frameBuffer.add(frame);

      if (_frameBuffer.isReady && !_inferenceInProgress) {
        _inferenceInProgress = true;
        try {
          final result = await _inferenceService.predict(_frameBuffer.snapshot);
          onResult?.call(result);
        } catch (e) {
          onError?.call('Inference error: $e');
        } finally {
          _inferenceInProgress = false;
          // Slide window by 10 frames
          if (_lastFrame != null) {
            for (int i = 0; i < 10; i++) {
              _frameBuffer.add(_lastFrame!);
            }
          }
        }
      }
    });

    print('[ASLPipeline] Started streaming.');
  }

  void stop() {
    _isRunning = false;
    _cameraController?.stopImageStream();
    _frameBuffer.clear();
    print('[ASLPipeline] Stopped.');
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
