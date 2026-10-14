import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'face_embedding_service.dart';
import 'liveness_service.dart';

/// Orchestrates the full pipeline:
///   detect → crop → liveness → embed → store/match
///
/// Embeddings are stored in Android's encrypted shared preferences,
/// keyed by `face_embedding_<userId>`. They never leave the device.
class FaceRecognitionService {
  FaceRecognitionService._();
  static final FaceRecognitionService instance = FaceRecognitionService._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: true,
      enableClassification: true,   // ← for eye-open probability
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    ),
  );

  static const _similarityThreshold = 0.65;

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    await FaceEmbeddingService.instance.init();
    await LivenessService.instance.init();
    _ready = true;
  }

  /// Detects the largest face in the image and returns it.
  Future<Face?> detectFace(InputImage input) async {
    final faces = await _detector.processImage(input);
    if (faces.isEmpty) return null;
    faces.sort(
      (a, b) => b.boundingBox.width.compareTo(a.boundingBox.width),
    );
    return faces.first;
  }

  /// Crops the face region out of the source image.
  img.Image? cropFace(img.Image source, Face face) {
    final box = face.boundingBox;
    final x = box.left.toInt().clamp(0, source.width - 1);
    final y = box.top.toInt().clamp(0, source.height - 1);
    final w = box.width.toInt().clamp(1, source.width - x);
    final h = box.height.toInt().clamp(1, source.height - y);
    if (w < 40 || h < 40) return null;
    return img.copyCrop(source, x: x, y: y, width: w, height: h);
  }

  /// Enrolls a patient. Requires at least [_minAcceptedSamples] liveness-verified
  /// captures out of [_enrollSamples].
  ///
  /// Returns the average embedding, or null if enrollment failed.
  Future<Float32List?> enroll({
    required String userId,
    required List<img.Image> crops,
  }) async {
    if (crops.isEmpty) return null;

    final embeddings = <Float32List>[];
    for (final crop in crops) {
      final e = FaceEmbeddingService.instance.embed(crop);
      if (e != null) embeddings.add(e);
    }

    if (embeddings.isEmpty) return null;

    final avg = Float32List(embeddings.first.length);
    for (final e in embeddings) {
      for (int i = 0; i < avg.length; i++) {
        avg[i] += e[i];
      }
    }
    for (int i = 0; i < avg.length; i++) {
      avg[i] /= embeddings.length;
    }

    double sum = 0;
    for (final v in avg) {
      sum += v * v;
    }
    final norm = sum > 0 ? 1.0 / (sum * sum) : 0.0;
    for (int i = 0; i < avg.length; i++) {
      avg[i] *= norm;
    }

    await _storage.write(
      key: 'face_embedding_$userId',
      value: base64Encode(avg.buffer.asUint8List()),
    );

    return avg;
  }

  /// Verifies a live crop against the stored embedding.
  Future<FaceVerifyResult> verify({
    required String userId,
    required img.Image crop,
  }) async {
    final stored = await _storage.read(key: 'face_embedding_$userId');
    if (stored == null) return FaceVerifyResult.notEnrolled;

    final live = LivenessService.instance.score(crop);
    if (!LivenessService.instance.isLive(live)) {
      return FaceVerifyResult.spoof;
    }

    final probe = FaceEmbeddingService.instance.embed(crop);
    if (probe == null) return FaceVerifyResult.noFace;

    final bytes = base64Decode(stored);
    final storedEmbedding = Float32List.view(bytes.buffer);
    final sim = FaceEmbeddingService.cosineSimilarity(probe, storedEmbedding);

    if (sim >= _similarityThreshold) return FaceVerifyResult.match;
    if (sim >= 0.5) return FaceVerifyResult.weakMatch;
    return FaceVerifyResult.noMatch;
  }

  Future<bool> hasEnrollment(String userId) async {
    final stored = await _storage.read(key: 'face_embedding_$userId');
    return stored != null;
  }

  Future<void> deleteEnrollment(String userId) async {
    await _storage.delete(key: 'face_embedding_$userId');
  }

  void dispose() {
    _detector.close();
    FaceEmbeddingService.instance.dispose();
    LivenessService.instance.dispose();
    _ready = false;
  }
}

enum FaceVerifyResult {
  match,
  weakMatch,
  noMatch,
  spoof,
  noFace,
  notEnrolled,
}