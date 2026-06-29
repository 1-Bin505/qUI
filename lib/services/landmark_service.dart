import 'dart:typed_data';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/frame_buffer.dart';
import '../utils/constants.dart';

// 33 valid PoseLandmarkType values from google_mlkit_pose_detection
// ⚠️ Confirm exact subset with ML team — this is the closest to
// Python MediaPipe Holistic's 33 pose points
final List<PoseLandmarkType> _extractedLandmarks = [
  PoseLandmarkType.nose,
  PoseLandmarkType.leftEyeInner,
  PoseLandmarkType.leftEye,
  PoseLandmarkType.leftEyeOuter,
  PoseLandmarkType.rightEyeInner,
  PoseLandmarkType.rightEye,
  PoseLandmarkType.rightEyeOuter,
  PoseLandmarkType.leftEar,
  PoseLandmarkType.rightEar,
  PoseLandmarkType.leftMouth,
  PoseLandmarkType.rightMouth,
  PoseLandmarkType.leftShoulder,
  PoseLandmarkType.rightShoulder,
  PoseLandmarkType.leftElbow,
  PoseLandmarkType.rightElbow,
  PoseLandmarkType.leftWrist,
  PoseLandmarkType.rightWrist,
  PoseLandmarkType.leftPinky,
  PoseLandmarkType.rightPinky,
  PoseLandmarkType.leftIndex,
  PoseLandmarkType.rightIndex,
  PoseLandmarkType.leftThumb,
  PoseLandmarkType.rightThumb,
  PoseLandmarkType.leftHip,
  PoseLandmarkType.rightHip,
  PoseLandmarkType.leftKnee,
  PoseLandmarkType.rightKnee,
  PoseLandmarkType.leftAnkle,
  PoseLandmarkType.rightAnkle,
  PoseLandmarkType.leftHeel,
  PoseLandmarkType.rightHeel,
  PoseLandmarkType.leftFootIndex,
  PoseLandmarkType.rightFootIndex,
]; // 33 points x 3 coords = 99 floats
   // remaining 48 floats (16 points) padded with wrist approximations

class LandmarkService {
  PoseDetector? _poseDetector;
  bool _initialized = false;

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  Future<void> initialize() async {
    if (_initialized) return;
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.accurate,
      ),
    );
    _initialized = true;
  }

  Future<LandmarkFrame?> extractFromFrame(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) async {
    assert(_initialized, 'Call initialize() first');

    final inputImage = _buildInputImage(image, camera, deviceOrientation);
    if (inputImage == null) return null;

    final poses = await _poseDetector!.processImage(inputImage);
    if (poses.isEmpty) return null;

    final pose = poses.first;
    final coords = Float32List(ASLConstants.landmarkFlatSize); // 147 floats
    int idx = 0;

    // ── 33 pose landmarks → 99 floats ─────────────────
    for (final type in _extractedLandmarks) {
      if (idx + 3 > ASLConstants.landmarkFlatSize) break;
      final lm = pose.landmarks[type];
      coords[idx++] = lm?.x ?? 0.0;
      coords[idx++] = lm?.y ?? 0.0;
      coords[idx++] = lm?.z ?? 0.0;
    }

    // ── Remaining 16 points → 48 floats ───────────────
    // Approximate missing hand detail using wrist positions
    final lw = pose.landmarks[PoseLandmarkType.leftWrist];
    final rw = pose.landmarks[PoseLandmarkType.rightWrist];

    while (idx < ASLConstants.landmarkFlatSize) {
      final lm = (idx % 6 < 3) ? lw : rw;
      coords[idx++] = lm?.x ?? 0.0;
      coords[idx++] = lm?.y ?? 0.0;
      coords[idx++] = lm?.z ?? 0.0;
    }

    return LandmarkFrame(coords: coords, timestamp: DateTime.now());
  }

  InputImage? _buildInputImage(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    try {
      final format = Platform.isAndroid
          ? InputImageFormat.nv21
          : InputImageFormat.bgra8888;

      final rotation = _getRotation(camera, deviceOrientation);

      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }

      return InputImage.fromBytes(
        bytes: allBytes.done().buffer.asUint8List(),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  InputImageRotation _getRotation(
    CameraDescription camera,
    DeviceOrientation orientation,
  ) {
    final sensorOrientation = camera.sensorOrientation;
    int compensation = _orientations[orientation] ?? 0;

    if (camera.lensDirection == CameraLensDirection.front) {
      compensation = (sensorOrientation + compensation) % 360;
    } else {
      compensation = (sensorOrientation - compensation + 360) % 360;
    }

    switch (compensation) {
      case 90:  return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default:  return InputImageRotation.rotation0deg;
    }
  }

  void dispose() {
    _poseDetector?.close();
    _initialized = false;
  }
}
