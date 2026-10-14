import 'package:flutter/material.dart';

import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_store.dart';
import '../../core/auth/pre_home_state.dart';
import '../../core/biometric/face_recognition_service.dart';
import '../../core/theme/caregiver_theme.dart';
import 'face_login_screen.dart';

class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen> {
  bool _hasEnrollment = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final user = AuthStore.instance.lastKnownUser;
    if (user == null) return;
    if (!user.biometricEnrolled) return;

    await FaceRecognitionService.instance.init();
    final ok = await FaceRecognitionService.instance.hasEnrollment(user.id);
    if (mounted) setState(() => _hasEnrollment = ok);
  }

  Future<void> _openFaceLogin() async {
    final user = AuthStore.instance.lastKnownUser;
    if (user == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FaceLoginScreen(
          onFallbackToPassword: () async {
            await AuthStore.instance.clearLastUser();
            await AuthStore.instance.setPhase(OnboardingPhase.none);
            if (mounted) Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _usePassword() async {
    await AuthStore.instance.clearLastUser();
    await AuthStore.instance.setPhase(OnboardingPhase.none);
    // PreHomeRouter rebuilds → Language Selection.
  }

  @override
  Widget build(BuildContext context) {
    final last = AuthStore.instance.lastKnownUser;
    if (last == null) return const SizedBox.shrink();

    final firstName = last.fullName.split(' ').first;
    final roleLabel = switch (last.role) {
      UserRole.patient => 'Patient',
      UserRole.caregiver => 'Caregiver',
      UserRole.family => 'Family Member',
    };

    return Scaffold(
      backgroundColor: CG.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: CG.primaryPale,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  last.fullName.isNotEmpty
                      ? last.fullName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: CG.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome back, $firstName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: CG.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                roleLabel,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: CG.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 40),

              if (_hasEnrollment) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _openFaceLogin,
                    icon: const Icon(Icons.face_retouching_natural_rounded,
                        size: 22),
                    label: const Text(
                      'Sign in with Face',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
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
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _usePassword,
                  icon: const Icon(Icons.password_rounded,
                      color: CG.primary, size: 20),
                  label: const Text(
                    'Use password instead',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: CG.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CG.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const Spacer(),
              const Text(
                'Session expired for your safety. Your account is intact.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: CG.textFaint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}