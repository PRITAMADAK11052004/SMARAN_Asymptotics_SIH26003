import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import '../../core/auth/auth_store.dart';
import '../../core/auth/pre_home_state.dart';
import '../../core/biometric/face_recognition_service.dart';
import '../../core/theme/caregiver_theme.dart';

class FaceLoginScreen extends StatefulWidget {
  final VoidCallback onFallbackToPassword;
  const FaceLoginScreen({super.key, required this.onFallbackToPassword});

  @override
  State<FaceLoginScreen> createState() => _FaceLoginScreenState();
}

class _FaceLoginScreenState extends State<FaceLoginScreen> {
  CameraController? _camera;
  bool _initializing = true;
  bool _busy = false;
  bool _success = false;
  String _hint = 'Look at the camera';
  int _attempts = 0;
  static const _maxAttempts = 20;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await FaceRecognitionService.instance.init();
      final cams = await availableCameras();
      if (cams.isEmpty) return;
      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      _camera = CameraController(
        front,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _camera!.initialize();
      if (!mounted) return;
      setState(() => _initializing = false);
      _loop();
    } catch (_) {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _loop() async {
    while (mounted && !_success && _attempts < _maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 1100));
      if (!mounted || _success) return;
      await _tryOnce();
    }
    if (mounted && !_success) {
      setState(() => _hint = 'Too many tries. Use password instead.');
    }
  }

  Future<void> _tryOnce() async {
    if (_busy || _success) return;
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;

    _busy = true;
    _attempts++;

    File? tmp;
    try {
      final shot = await cam.takePicture();
      final bytes = await File(shot.path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;

      final upright = img.copyRotate(
        decoded,
        angle: cam.description.sensorOrientation,
      );

      tmp = File(
        '${Directory.systemTemp.path}/smaran_verify_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await tmp.writeAsBytes(img.encodeJpg(upright));

      final inputImage = InputImage.fromFilePath(tmp.path);
      final face =
          await FaceRecognitionService.instance.detectFace(inputImage);
      if (face == null) {
        if (mounted) setState(() => _hint = 'No face detected');
        return;
      }

      final crop =
          FaceRecognitionService.instance.cropFace(upright, face);
      if (crop == null) return;

      final user = AuthStore.instance.lastKnownUser;
      if (user == null) return;

      final result = await FaceRecognitionService.instance.verify(
        userId: user.id,
        crop: crop,
      );

      if (!mounted) return;

      switch (result) {
        case FaceVerifyResult.match:
          setState(() {
            _success = true;
            _hint = 'Verified';
          });
          await AuthStore.instance.reissueSessionFor(user.id);
          await AuthStore.instance.setPhase(OnboardingPhase.home);
          // RootGate takes over — navigates to role splash → Home.
          break;
        case FaceVerifyResult.spoof:
          setState(() => _hint = 'Please look directly at the camera');
          break;
        case FaceVerifyResult.weakMatch:
          setState(() => _hint = 'Almost — hold steady');
          break;
        case FaceVerifyResult.noFace:
          setState(() => _hint = 'Face not clear');
          break;
        case FaceVerifyResult.notEnrolled:
          setState(() => _hint = 'No face enrolled');
          break;
        case FaceVerifyResult.noMatch:
          setState(() => _hint = 'Recognising…');
          break;
      }
    } catch (_) {
      // silently retry
    } finally {
      if (tmp != null && tmp.existsSync()) {
        try {
          tmp.deleteSync();
        } catch (_) {}
      }
      _busy = false;
    }
  }

  @override
  void dispose() {
    _success = true;
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _camera != null && _camera!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (_initializing || !ready)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            else
              Center(child: CameraPreview(_camera!)),

            Center(
              child: Container(
                width: 260,
                height: 320,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _success ? CG.success : Colors.white,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(200),
                ),
                alignment: Alignment.center,
                child: _success
                    ? const Icon(Icons.check_circle_rounded,
                        color: CG.success, size: 100)
                    : null,
              ),
            ),

            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  Text(
                    _hint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: widget.onFallbackToPassword,
                    child: const Text(
                      'Use password instead',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}