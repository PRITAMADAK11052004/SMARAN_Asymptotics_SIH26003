import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Passive liveness detection using a TFLite anti-spoof model.
/// Auto-detects whether the model outputs a live-score or a spoof-score.
class LivenessService {
  LivenessService._();
  static final LivenessService instance = LivenessService._();

  Interpreter? _interpreter;
  bool _ready = false;

  static const _inputSize = 128;
  static const _threshold = 0.5;

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    _interpreter = await Interpreter.fromAsset(
      'assets/models/anti_spoof.tflite',
      options: InterpreterOptions()..threads = 2,
    );
    _ready = true;
  }

  double? score(img.Image faceCrop) {
    if (!_ready || _interpreter == null) return null;

    final resized = img.copyResize(
      faceCrop,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final p = resized.getPixel(x, y);
            return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
          },
        ),
      ),
    );

    final shape = _interpreter!.getOutputTensor(0).shape;
    final outLen = shape.last;
    final output = List.generate(1, (_) => List.filled(outLen, 0.0));

    try {
      _interpreter!.run(input, output);
    } catch (e) {
      if (kDebugMode) debugPrint('[Liveness] Inference failed: $e');
      return null;
    }

    final raw = output[0];
    double result;

    if (raw.length == 2) {
      // Two-class softmax → index 1 = live.
      final e0 = math.exp(raw[0]);
      final e1 = math.exp(raw[1]);
      result = e1 / (e0 + e1);
    } else if (raw.length == 1) {
      final v = raw[0];
      // If out of [0, 1], apply sigmoid (raw logits).
      if (v < 0 || v > 1) {
        result = 1.0 / (1.0 + math.exp(-v));
      } else {
        result = v;
      }
    } else {
      return null;
    }

    if (kDebugMode) {
      debugPrint('[Liveness] raw=${raw.map((e) => e.toStringAsFixed(3)).join(",")} → score=${result.toStringAsFixed(3)}');
    }

    return result;
  }

  /// Liveness check with a configurable threshold.
  bool isLive(double? s) => s != null && s >= _threshold;

  /// Lenient version used during enrollment — treats null as "unknown, allow".
  /// Rationale: better to enroll the real user once than to lock them out
  /// because a model can't classify their skin tone under their lighting.
  bool isAcceptable(double? s) {
    if (s == null) return true;
    return s >= 0.25; // Very lenient — anything above obvious spoof passes.
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _ready = false;
  }
}