import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceEmbeddingService {
  FaceEmbeddingService._();
  static final FaceEmbeddingService instance = FaceEmbeddingService._();

  Interpreter? _interpreter;
  bool _ready = false;

  int _batch = 1;
  int _channels = 3;
  int _h = 112;
  int _w = 112;
  int _embeddingSize = 128;
  bool _nchw = true;

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;

    _interpreter = await Interpreter.fromAsset(
      'assets/models/mobilefacenet.tflite',
      options: InterpreterOptions()..threads = 4,
    );

    final inShape = _interpreter!.getInputTensor(0).shape;
    final outShape = _interpreter!.getOutputTensor(0).shape;

    if (kDebugMode) {
      debugPrint('[Embed] raw input shape: $inShape');
      debugPrint('[Embed] raw output shape: $outShape');
    }

    // Detect layout: NCHW has 3 in position 1, NHWC has 3 in last position.
    if (inShape.length == 4) {
      if (inShape[1] == 3) {
        _nchw = true;
        _batch = inShape[0];
        _channels = inShape[1];
        _h = inShape[2];
        _w = inShape[3];
      } else if (inShape[3] == 3) {
        _nchw = false;
        _batch = inShape[0];
        _h = inShape[1];
        _w = inShape[2];
        _channels = inShape[3];
      }
    }

    // Embedding size = product of all dims after batch.
    _embeddingSize = outShape.sublist(1).reduce((a, b) => a * b);

    if (kDebugMode) {
      debugPrint('[Embed] layout=${_nchw ? "NCHW" : "NHWC"} '
          'batch=$_batch channels=$_channels ${_h}x$_w '
          'embedding=$_embeddingSize');
    }

    _ready = true;
  }

  Float32List? embed(img.Image faceCrop) {
    if (!_ready || _interpreter == null) return null;

    final resized = img.copyResize(
      faceCrop,
      width: _w,
      height: _h,
      interpolation: img.Interpolation.linear,
    );

    // Build input matching the model's declared shape.
    final List<List<List<List<double>>>> input = _buildInput(resized);

    // Allocate output with the exact shape the model wants.
    final outShape = _interpreter!.getOutputTensor(0).shape;
    final output = List.generate(
      outShape[0],
      (_) => List.filled(_embeddingSize, 0.0),
    );

    try {
      _interpreter!.run(input, output);
    } catch (e) {
      if (kDebugMode) debugPrint('[Embed] run failed: $e');
      return null;
    }

    // Take batch index 0 (all copies are identical since we fed the same image).
    final raw = Float32List.fromList(output[0].cast<double>());
    final normalized = _l2Normalize(raw);

    if (kDebugMode) {
      final sample =
          normalized.take(3).map((e) => e.toStringAsFixed(3)).join(', ');
      debugPrint('[Embed] OK — first 3 dims: [$sample]');
    }

    return normalized;
  }

  List<List<List<List<double>>>> _buildInput(img.Image resized) {
    if (_nchw) {
      // [batch][channel][h][w]
      return List.generate(
        _batch,
        (_) => List.generate(
          _channels,
          (c) => List.generate(
            _h,
            (y) => List.generate(
              _w,
              (x) => _pixel(resized, x, y, c),
            ),
          ),
        ),
      );
    } else {
      // [batch][h][w][channel]
      return List.generate(
        _batch,
        (_) => List.generate(
          _h,
          (y) => List.generate(
            _w,
            (x) => List.generate(
              _channels,
              (c) => _pixel(resized, x, y, c),
            ),
          ),
        ),
      );
    }
  }

  double _pixel(img.Image im, int x, int y, int c) {
    final p = im.getPixel(x, y);
    final v = c == 0 ? p.r : (c == 1 ? p.g : p.b);
    return (v - 127.5) / 128.0;
  }

  Float32List _l2Normalize(Float32List v) {
    double sum = 0;
    for (final x in v) {
      sum += x * x;
    }
    final norm = math.sqrt(sum);
    if (norm < 1e-8) return v;
    final out = Float32List(v.length);
    for (int i = 0; i < v.length; i++) {
      out[i] = v[i] / norm;
    }
    return out;
  }

  static double cosineSimilarity(Float32List a, Float32List b) {
    if (a.length != b.length) return 0;
    double dot = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _ready = false;
  }
}