// lib/models/frame_buffer.dart
//
// Rolling frame buffer — accumulates 30 frames of landmark data.
// Once full, it returns a snapshot ready for inference.
// Thread-safe for use from camera callback + isolate.

import 'dart:typed_data';
import '../utils/constants.dart';

class LandmarkFrame {
  /// Flattened landmark coords for one frame: [x0,y0,z0, x1,y1,z1, ...]
  /// Length = ASLConstants.landmarkFlatSize (147)
  final Float32List coords;
  final DateTime timestamp;

  LandmarkFrame({required this.coords, required this.timestamp})
      : assert(coords.length == ASLConstants.landmarkFlatSize,
            'Expected ${ASLConstants.landmarkFlatSize} coords, got ${coords.length}');
}

class FrameBuffer {
  final _buffer = <LandmarkFrame>[];
  final int _capacity = ASLConstants.sequenceLength; // 30

  /// Add one landmark frame. Drops oldest if over capacity.
  void add(LandmarkFrame frame) {
    _buffer.add(frame);
    if (_buffer.length > _capacity) {
      _buffer.removeAt(0);
    }
  }

  /// True when we have exactly [sequenceLength] frames buffered.
  bool get isReady => _buffer.length == _capacity;

  /// Returns current fill level (0–30).
  int get fillLevel => _buffer.length;

  /// Returns a flat snapshot of the current buffer as Float32List
  /// Shape (logical): [30, 147] → flattened to [30 * 147] = [4410]
  /// The TFLite service reshapes this into [1, 30, 147] before inference.
  Float32List get snapshot {
    assert(isReady, 'Buffer not full yet (${_buffer.length}/$_capacity frames)');
    final flat = Float32List(_capacity * ASLConstants.landmarkFlatSize);
    for (int f = 0; f < _capacity; f++) {
      final offset = f * ASLConstants.landmarkFlatSize;
      flat.setRange(offset, offset + ASLConstants.landmarkFlatSize, _buffer[f].coords);
    }
    return flat;
  }

  void clear() => _buffer.clear();
}