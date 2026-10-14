import 'package:flutter/material.dart';
import '../../core/auth/auth_store.dart';
import '../../core/auth/pre_home_state.dart';
import '../../core/domain/app_models.dart';
import 'face_enrollment_screen.dart';
import 'language_selection_screen.dart';
import 'link_prompt_screen.dart';
import 'login_screen.dart';
import 'otp_entry_screen.dart';
import 'otp_method_screen.dart';
import 'registration_screen.dart';
import 'role_selection_screen.dart';
import 'smrn_reveal_screen.dart';
import 'welcome_back_screen.dart';

class PreHomeRouter extends StatefulWidget {
  final SmaranStore store;
  const PreHomeRouter({super.key, required this.store});

  @override
  State<PreHomeRouter> createState() => _PreHomeRouterState();
}

class _PreHomeRouterState extends State<PreHomeRouter> {
  @override
  void initState() {
    super.initState();
    AuthStore.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    AuthStore.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthStore.instance;

    // 1. Mid-onboarding phases — always take priority.
    switch (auth.phase) {
      case OnboardingPhase.login:
        if (auth.pendingRole != null) {
          return LoginScreen(role: auth.pendingRole!);
        }
        break;
      case OnboardingPhase.registration:
        if (auth.pendingRole != null) {
          return RegistrationScreen(role: auth.pendingRole!);
        }
        break;
      case OnboardingPhase.otpMethod:
        return const OtpMethodScreen();
      case OnboardingPhase.otpEntry:
        return const OtpEntryScreen();
      case OnboardingPhase.faceSetup:
        return const FaceEnrollmentScreen();
      case OnboardingPhase.smrnReveal:
        return const SmrnRevealScreen();
      case OnboardingPhase.linkPrompt:
        return const LinkPromptScreen();
      case OnboardingPhase.none:
      case OnboardingPhase.home:
        break;
    }

    // 2. Returning user with invalid/expired session.
    if (!auth.isLoggedIn && auth.lastKnownUser != null) {
      return const WelcomeBackScreen();
    }

    // 3. Language selection.
    if (!auth.hasChosenLanguage) {
      return const LanguageSelectionScreen();
    }

    // 4. Role selection.
    return const RoleSelectionScreen();
  }
}