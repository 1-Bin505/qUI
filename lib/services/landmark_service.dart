// lib/services/landmark_service.dart
//
// MediaPipe landmark extraction.
//
// ⚠️ google_mediapipe is in early preview and its Flutter API is unstable.
//    This file compiles cleanly by importing only what's confirmed available.
//    The extractFromFrame() method is stubbed with zero-padded coords —
//    replace the body once your team confirms the exact MediaPipe plugin version.

import 'dart:typed_data';
import 'package:camera/camera.dart';
import '../models/frame_buffer.dart';
import '../utils/constants.dart';

class LandmarkService {
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    // TODO: initialize your MediaPipe Holistic/Hand landmarker here
    // e.g. await HolisticLandmarker.create(options: ...)
    _initialized = true;
  }

  /// Extract landmarks from one camera frame.
  /// Returns null if no hands detected.
  ///
  /// ⚠️ STUB: currently returns zero-padded coords so the pipeline
  ///    compiles and runs end-to-end. Replace inner body with real
  ///    MediaPipe calls once plugin version is confirmed with your team.
  Future<LandmarkFrame?> extractFromFrame(CameraImage image) async {
    assert(_initialized, 'Call initialize() first');

    // ── REAL IMPLEMENTATION GOES HERE ──────────────────
    // Example (adjust to your plugin's actual API):
    //
    // final mpImage = MPImage.fromCameraImage(image);
    // final result = await _holistic.detect(mpImage);
    // if (result == null) return null;
    //
    // final coords = Float32List(ASLConstants.landmarkFlatSize);
    // int idx = 0;
    // for (final lm in result.poseLandmarks ?? []) {
    //   if (idx + 3 > coords.length) break;
    //   coords[idx++] = lm.x; coords[idx++] = lm.y; coords[idx++] = lm.z;
    // }
    // for (final lm in result.rightHandLandmarks ?? []) {
    //   if (idx + 3 > coords.length) break;
    //   coords[idx++] = lm.x; coords[idx++] = lm.y; coords[idx++] = lm.z;
    // }
    // return LandmarkFrame(coords: coords, timestamp: DateTime.now());
    // ───────────────────────────────────────────────────

    // STUB: zero-padded (remove once real MediaPipe is wired in)
    final coords = Float32List(ASLConstants.landmarkFlatSize);
    return LandmarkFrame(coords: coords, timestamp: DateTime.now());
  }

  void dispose() {
    _initialized = false;
  }
}