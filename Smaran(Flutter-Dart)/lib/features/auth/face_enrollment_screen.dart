import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../core/auth/auth_store.dart';
import '../../core/auth/pre_home_state.dart';
import '../../core/biometric/face_recognition_service.dart';
import '../../core/theme/caregiver_theme.dart';
import 'face_liveness_controller.dart';

enum _UiPhase { intro, live, success, failed }

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen> {
  _UiPhase _ui = _UiPhase.intro;
  CameraController? _camera;
  FaceLivenessController? _liveness;
  bool _camReady = false;
  bool _faceInFrame = false;
  bool _flipping = false;
  String? _error;

  FaceStep _step = FaceStep.initializing;
  String _hint = 'Preparing camera...';
  int _done = 0;
  int _total = 3;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await FaceRecognitionService.instance.init();
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() => _error = 'No camera available on this device.');
        return;
      }
      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      _camera = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await _camera!.initialize();
      if (!mounted) return;
      setState(() => _camReady = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Camera failed: $e');
    }
  }

  Future<void> _flipCamera() async {
    if (_flipping) return;
    _flipping = true;

    try {
      final current = _camera;
      if (current == null) return;

      final newLens = current.description.lensDirection ==
              CameraLensDirection.front
          ? CameraLensDirection.back
          : CameraLensDirection.front;

      final cams = await availableCameras();
      final next = cams.firstWhere(
        (c) => c.lensDirection == newLens,
        orElse: () => cams.first,
      );

      // Detach liveness from the old camera first.
      await _liveness?.dispose();
      _liveness = null;

      await current.dispose();

      final newController = CameraController(
        next,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await newController.initialize();
      if (!mounted) return;

      setState(() {
        _camera = newController;
        _done = 0;
        _step = FaceStep.initializing;
        _hint = 'Preparing camera...';
      });

      // If we were already in liveness, restart it with the new camera.
      if (_ui == _UiPhase.live) {
        await _startScan();
      }
    } catch (_) {
    } finally {
      _flipping = false;
    }
  }

  Future<void> _startScan() async {
    if (_camera == null) return;

    _liveness = FaceLivenessController(
      onStepChanged: (s) => setState(() => _step = s),
      onHintChanged: (h) => setState(() => _hint = h),
      onProgressChanged: (done, total) => setState(() {
        _done = done;
        _total = total;
      }),
      onFaceInFrameChanged: (inFrame) =>
          setState(() => _faceInFrame = inFrame),
      onError: (e) => setState(() => _error = e),
      onSuccess: _onLivenessSuccess,
    );

    setState(() {
      _ui = _UiPhase.live;
      _done = 0;
      _error = null;
    });

    await _liveness!.start(_camera!.description, _camera!);
  }

  Future<void> _onLivenessSuccess(List<img.Image> frames) async {
    final user = AuthStore.instance.currentUser;
    if (user == null) return;

    final embedding = await FaceRecognitionService.instance.enroll(
      userId: user.id,
      crops: frames,
    );

    if (!mounted) return;

    if (embedding == null) {
      setState(() {
        _ui = _UiPhase.failed;
        _error = 'We could not complete verification. Please try again.';
      });
      return;
    }

    try {
      final sample = frames[frames.length ~/ 2];
      final jpeg = img.encodeJpg(sample, quality: 80);
      await AuthStore.instance.setFacePhoto(base64Encode(jpeg));
    } catch (_) {}

    await AuthStore.instance.setBiometricEnrolled(true);
    await AuthStore.instance.ensurePatientId();

    if (!mounted) return;
    setState(() => _ui = _UiPhase.success);

    await Future.delayed(const Duration(milliseconds: 900));
    await AuthStore.instance.setPhase(OnboardingPhase.smrnReveal);
  }

  Future<void> _stopAndRetry() async {
    await _liveness?.dispose();
    _liveness = null;
    setState(() {
      _ui = _UiPhase.intro;
      _error = null;
      _done = 0;
      _faceInFrame = false;
    });
  }

  @override
  void dispose() {
    _liveness?.dispose();
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_ui) {
      case _UiPhase.intro:
        return _buildIntro();
      case _UiPhase.live:
        return _buildLive();
      case _UiPhase.success:
        return _buildSuccess();
      case _UiPhase.failed:
        return _buildFailed();
    }
  }

  Widget _buildIntro() {
    return Scaffold(
      backgroundColor: CG.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar('Face Verification', showFlip: false),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      "Let's verify your identity",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: CG.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Position your face inside the frame',
                      style: TextStyle(fontSize: 13, color: CG.textMuted),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: CG.border),
                      ),
                      child: Center(
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: const BoxDecoration(
                            color: CG.primaryPale,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded,
                              size: 80, color: CG.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _infoRow(Icons.wb_sunny_rounded,
                        'Make sure your face is clearly visible and there is enough light.'),
                    const SizedBox(height: 12),
                    _infoRow(Icons.sentiment_satisfied_rounded,
                        'This helps us keep your account safe and secure.'),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed:
                            _camReady && _error == null ? _startScan : null,
                        icon: const Icon(Icons.camera_alt_rounded, size: 22),
                        label: const Text(
                          'Start Face Scan',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: CG.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12.5,
                            color: CG.danger,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLive() {
    final ready = _camera != null && _camera!.value.isInitialized;
    // ⭐ Circle color: green when face in frame, red when out.
    final ringColor = _faceInFrame ? CG.success : CG.danger;

    return Scaffold(
      backgroundColor: CG.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar('Face Verification', showFlip: true),
            const SizedBox(height: 8),
            Text(
              _stepTitle(),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: CG.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _hint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: CG.textMuted),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (!ready)
                        Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white),
                          ),
                        )
                      else
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _camera!.value.previewSize!.height,
                            height: _camera!.value.previewSize!.width,
                            child: CameraPreview(_camera!),
                          ),
                        ),
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ringColor,
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.touch_app_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _instruction(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_total, (i) {
                final filled = i < _done;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: filled ? 26 : 18,
                  height: 8,
                  decoration: BoxDecoration(
                    color: filled ? CG.primary : CG.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _stepTile(
                      icon: Icons.visibility_rounded,
                      label: '1. Blink once',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _stepTile(
                      icon: Icons.rotate_right_rounded,
                      label: '2. Turn left & right',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _stepTile(
                icon: Icons.center_focus_strong_rounded,
                label: '3. Return to center & hold',
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: CG.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: CG.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 52),
              ),
              const SizedBox(height: 20),
              const Text(
                "You're verified!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: CG.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your identity has been confirmed.',
                style: TextStyle(fontSize: 13.5, color: CG.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFailed() {
    return Scaffold(
      backgroundColor: CG.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFFFADCDC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded,
                    color: CG.danger, size: 46),
              ),
              const SizedBox(height: 20),
              const Text(
                "That's okay. Let's try again.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: CG.primary),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Please ensure good lighting and try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: CG.textMuted, height: 1.5),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _stopAndRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Try Again',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: CG.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _stepTitle() {
    switch (_step) {
      case FaceStep.searching:
      case FaceStep.faceReady:
        return 'Please face the camera';
      case FaceStep.blink:
        return 'Blink your eyes once';
      case FaceStep.turnLeft:
        return 'Slowly turn your face left';
      case FaceStep.turnRight:
        return 'Slowly turn your face right';
      case FaceStep.returnCenter:
        return 'Look at the screen';
      case FaceStep.holdStill:
        return 'Hold still...';
      case FaceStep.capturing:
        return 'Taking your photo...';
      case FaceStep.verifying:
        return 'Checking your face...';
      default:
        return 'Preparing camera...';
    }
  }

  String _instruction() {
    switch (_step) {
      case FaceStep.blink:
        return 'Look at the screen and blink naturally';
      case FaceStep.turnLeft:
        return 'Turn slowly. Take your time.';
      case FaceStep.turnRight:
        return 'Turn slowly. Take your time.';
      case FaceStep.returnCenter:
        return 'Bring your face back to the center';
      case FaceStep.holdStill:
        return 'Please stay still for a moment';
      case FaceStep.capturing:
        return 'Just a moment.';
      case FaceStep.verifying:
        return 'Just a moment. We are checking your face.';
      default:
        return 'Keep your face inside the circle';
    }
  }

  Widget _stepTile({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CG.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: CG.primaryPale,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: CG.primary, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: CG.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: CG.primaryPale,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: CG.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: CG.textPrimary,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _topBar(String title, {required bool showFlip}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: CG.primary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: CG.primary,
              ),
            ),
          ),
          showFlip
              ? IconButton(
                  icon: _flipping
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: CG.primary,
                          ),
                        )
                      : const Icon(Icons.flip_camera_android_rounded,
                          color: CG.primary),
                  onPressed: _flipping ? null : _flipCamera,
                  tooltip: 'Flip Camera',
                )
              : const SizedBox(width: 48),
        ],
      ),
    );
  }
}