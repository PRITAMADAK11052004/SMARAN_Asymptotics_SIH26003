import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

enum FaceStep {
  initializing,
  searching,
  faceReady,
  blink,
  turnLeft,
  turnRight,
  returnCenter,
  holdStill,
  capturing,
  verifying,
  success,
  failed,
}

class FaceLivenessController {
  FaceLivenessController({
    required this.onStepChanged,
    required this.onHintChanged,
    required this.onProgressChanged,
    required this.onFaceInFrameChanged,
    required this.onError,
    required this.onSuccess,
  });

  final void Function(FaceStep) onStepChanged;
  final void Function(String) onHintChanged;
  final void Function(int done, int total) onProgressChanged;
  final void Function(bool inFrame) onFaceInFrameChanged;
  final void Function(String) onError;
  final void Function(List<img.Image> bestFrames) onSuccess;

  CameraController? _camera;

  final _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      enableClassification: true,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    ),
  );

  FaceStep _step = FaceStep.initializing;
  Timer? _stepTimer;
  DateTime _stepStarted = DateTime.now();
  bool _running = false;

  int _blinkPhase = 0;
  DateTime? _holdStart;

  static const _eyeClosed = 0.30;
  static const _eyeOpen = 0.60;
  static const _turnMin = 12.0;
  static const _centerMax = 12.0;
  static const _holdMs = 1200;
  static const _maxStepSeconds = 20;

  Future<void> start(CameraDescription desc, CameraController controller) async {
    _camera = controller;
    _running = true;
    _setStep(FaceStep.searching, 'Please face the camera');
    await controller.startImageStream(_onFrame);

    _stepTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_running) return;
      final elapsed = DateTime.now().difference(_stepStarted).inSeconds;
      if (elapsed > _maxStepSeconds && _step != FaceStep.success) {
        _resetStep();
      }
    });
  }

  /// Called after flip — reattach to a new controller.
  Future<void> reattach(CameraController newController) async {
    try {
      if (_camera?.value.isStreamingImages ?? false) {
        await _camera!.stopImageStream();
      }
    } catch (_) {}
    _camera = newController;
    if (_running) {
      await newController.startImageStream(_onFrame);
    }
  }

  void _resetStep() {
    switch (_step) {
      case FaceStep.blink:
        _blinkPhase = 0;
        _setStep(FaceStep.blink, 'Blink your eyes once');
        break;
      case FaceStep.turnLeft:
        _setStep(FaceStep.turnLeft, 'Slowly turn your face left');
        break;
      case FaceStep.turnRight:
        _setStep(FaceStep.turnRight, 'Slowly turn your face right');
        break;
      case FaceStep.returnCenter:
        _setStep(FaceStep.returnCenter, 'Look at the screen');
        break;
      default:
        break;
    }
  }

  void _setStep(FaceStep s, String hint) {
    _step = s;
    _stepStarted = DateTime.now();
    onStepChanged(s);
    onHintChanged(hint);
  }

  Future<void> _onFrame(CameraImage image) async {
    if (!_running) return;
    if (_step == FaceStep.capturing || _step == FaceStep.verifying) return;

    try {
      final input = _toInputImage(image);
      if (input == null) return;
      final faces = await _detector.processImage(input);
      if (!_running) return;
      _handleFaces(faces, image);
    } catch (_) {}
  }

  void _handleFaces(List<Face> faces, CameraImage image) {
    if (faces.isEmpty) {
      onFaceInFrameChanged(false);
      if (_step == FaceStep.searching) {
        onHintChanged('Please bring your face a little closer');
      }
      return;
    }
    if (faces.length > 1) {
      onFaceInFrameChanged(false);
      onHintChanged('Please make sure only one person is in the frame');
      return;
    }

    final face = faces.first;
    final faceRatio = face.boundingBox.width / image.width;

    if (faceRatio < 0.25) {
      onFaceInFrameChanged(false);
      onHintChanged('Please move a little closer');
      return;
    }

    // Face is in-frame and usable.
    onFaceInFrameChanged(true);

    switch (_step) {
      case FaceStep.searching:
        _setStep(FaceStep.faceReady, 'Great! We can see your face');
        Future.delayed(const Duration(milliseconds: 600), () {
          if (_running && _step == FaceStep.faceReady) {
            _setStep(FaceStep.blink, 'Blink your eyes once');
          }
        });
        break;

      case FaceStep.blink:
        final l = face.leftEyeOpenProbability ?? 0.5;
        final r = face.rightEyeOpenProbability ?? 0.5;
        final open = l > _eyeOpen && r > _eyeOpen;
        final closed = l < _eyeClosed && r < _eyeClosed;
        if (_blinkPhase == 0 && closed) {
          _blinkPhase = 1;
        } else if (_blinkPhase == 1 && open) {
          _blinkPhase = 2;
          onProgressChanged(1, 3);
          _setStep(FaceStep.turnLeft, 'Slowly turn your face left');
        }
        break;

      case FaceStep.turnLeft:
        final yaw = face.headEulerAngleY ?? 0;
        if (yaw > _turnMin) {
          onProgressChanged(2, 3);
          _setStep(FaceStep.turnRight, 'Slowly turn your face right');
        }
        break;

      case FaceStep.turnRight:
        final yaw = face.headEulerAngleY ?? 0;
        if (yaw < -_turnMin) {
          onProgressChanged(3, 3);
          _setStep(FaceStep.returnCenter, 'Look at the screen');
        }
        break;

      case FaceStep.returnCenter:
        final yaw = face.headEulerAngleY ?? 0;
        final centered = yaw.abs() < _centerMax;
        final eyesVisible =
            (face.leftEyeOpenProbability ?? 0) > 0.3 &&
                (face.rightEyeOpenProbability ?? 0) > 0.3;
        if (centered && eyesVisible) {
          _holdStart = DateTime.now();
          _setStep(FaceStep.holdStill, 'Hold still...');
        }
        break;

      case FaceStep.holdStill:
        final elapsed =
            DateTime.now().difference(_holdStart!).inMilliseconds;
        if (elapsed >= _holdMs) {
          _captureFinalFrame();
        }
        break;

      default:
        break;
    }
  }

  Future<void> _captureFinalFrame() async {
    if (_step != FaceStep.holdStill) return;
    _setStep(FaceStep.capturing, 'Taking your photo...');

    try {
      if (_camera?.value.isStreamingImages ?? false) {
        await _camera!.stopImageStream();
      }
      await Future.delayed(const Duration(milliseconds: 200));

      final shot = await _camera!.takePicture();
      final file = File(shot.path);

      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        onError('Could not read your photo.');
        _setStep(FaceStep.failed, 'Try again');
        return;
      }

      final upright = img.bakeOrientation(decoded);

      final input = InputImage.fromFilePath(file.path);
      final faces = await _detector.processImage(input);
      if (faces.isEmpty) {
        onError("We lost your face. Let's try again.");
        _setStep(FaceStep.failed, 'Try again');
        return;
      }

      final face = faces.first;
      final box = face.boundingBox;
      final x = box.left.toInt().clamp(0, upright.width - 1);
      final y = box.top.toInt().clamp(0, upright.height - 1);
      final w = box.width.toInt().clamp(1, upright.width - x);
      final h = box.height.toInt().clamp(1, upright.height - y);

      if (w < 60 || h < 60) {
        onError('Photo too small. Move closer next time.');
        _setStep(FaceStep.failed, 'Try again');
        return;
      }

      final crop =
          img.copyCrop(upright, x: x, y: y, width: w, height: h);

      _setStep(FaceStep.verifying, 'Checking your face...');
      await Future.delayed(const Duration(milliseconds: 300));

      _running = false;
      onSuccess([crop]);
    } catch (e) {
      onError('Something went wrong. Please try again.');
      _setStep(FaceStep.failed, 'Try again');
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final rotation =
        _rotationFromSensor(_camera?.description.sensorOrientation ?? 0);
    try {
      if (image.planes.length == 1) {
        return InputImage.fromBytes(
          bytes: image.planes[0].bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.nv21,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      } else if (image.planes.length >= 3) {
        final nv21 = _yuv420ToNv21(image);
        return InputImage.fromBytes(
          bytes: nv21,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.nv21,
            bytesPerRow: image.width,
          ),
        );
      }
    } catch (_) {}
    return null;
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final ySize = width * height;
    final uvSize = width * height ~/ 2;
    final out = Uint8List(ySize + uvSize);

    final yPlane = image.planes[0];
    if (yPlane.bytesPerRow == width) {
      out.setRange(0, ySize, yPlane.bytes);
    } else {
      int o = 0;
      for (int row = 0; row < height; row++) {
        out.setRange(o, o + width, yPlane.bytes, row * yPlane.bytesPerRow);
        o += width;
      }
    }

    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 2;
    int o = ySize;
    for (int row = 0; row < height ~/ 2; row++) {
      for (int col = 0; col < width ~/ 2; col++) {
        final idx = row * uvRowStride + col * uvPixelStride;
        out[o++] = vPlane.bytes[idx];
        out[o++] = uPlane.bytes[idx];
      }
    }
    return out;
  }

  InputImageRotation _rotationFromSensor(int s) {
    switch (s) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> dispose() async {
    _running = false;
    _stepTimer?.cancel();
    try {
      if (_camera?.value.isStreamingImages ?? false) {
        await _camera!.stopImageStream();
      }
    } catch (_) {}
    _detector.close();
  }
}