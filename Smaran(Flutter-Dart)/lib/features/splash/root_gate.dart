import 'package:flutter/material.dart';

import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_store.dart';
import '../../core/auth/pre_home_state.dart';
import '../../core/domain/app_models.dart';
import '../../core/theme/caregiver_theme.dart';
import '../auth/pre_home_router.dart';
import '../caregiver/caregiver_shell.dart';
import '../family/family_shell.dart';
import '../shell/shell.dart';
import 'role_splashes.dart';

class RootGate extends StatefulWidget {
  final SmaranStore store;
  const RootGate({super.key, required this.store});

  @override
  State<RootGate> createState() => _RootGateState();
}

enum _GateState { booting, defaultSplash, roleSplash, home, onboarding }

class _RootGateState extends State<RootGate> {
  _GateState _state = _GateState.booting;
  UserRole? _role;
  String? _splashShownForUserId;

  /// Phases that mean "user is still in the pre-home onboarding flow".
  /// While in any of these, RootGate must NOT jump to the splash/Home.
  static const _midOnboarding = {
    OnboardingPhase.login,
    OnboardingPhase.registration,
    OnboardingPhase.otpMethod,
    OnboardingPhase.otpEntry,
    OnboardingPhase.faceSetup,
    OnboardingPhase.smrnReveal,
    OnboardingPhase.linkPrompt,
  };

  @override
  void initState() {
    super.initState();
    AuthStore.instance.addListener(_onAuthChanged);
    _decide();
  }

  @override
  void dispose() {
    AuthStore.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    _decide();
  }

  void _decide() {
    final auth = AuthStore.instance;
    final user = auth.currentUser;

    // ── Logged in ─────────────────────────────────────────────
    if (auth.isLoggedIn && user != null) {
      // Mid-onboarding → defer entirely to PreHomeRouter.
      // This is the fix: after OTP verify, isLoggedIn == true, but
      // phase == faceSetup (or linkPrompt), so we must NOT show splash yet.
      if (_midOnboarding.contains(auth.phase)) {
        _splashShownForUserId = null;
        if (_state != _GateState.onboarding) {
          setState(() => _state = _GateState.onboarding);
        }
        return;
      }

      // phase == home (fully onboarded) → role splash → Home.
      if (_splashShownForUserId != user.id) {
        if (_state != _GateState.roleSplash) {
          setState(() {
            _role = user.role;
            _splashShownForUserId = user.id;
            _state = _GateState.roleSplash;
          });
        }
        return;
      }

      if (_state != _GateState.home) {
        setState(() => _state = _GateState.home);
      }
      return;
    }

    // ── Not logged in ────────────────────────────────────────
    _splashShownForUserId = null;

    // Any onboarding activity → PreHomeRouter.
    if (auth.phase != OnboardingPhase.none ||
        auth.hasChosenLanguage ||
        auth.pendingRole != null ||
        auth.lastKnownUser != null) {
      if (_state != _GateState.onboarding) {
        setState(() => _state = _GateState.onboarding);
      }
      return;
    }

    // Fresh install → default splash first.
    if (_state == _GateState.booting) {
      setState(() => _state = _GateState.defaultSplash);
    }
  }

  void _onDefaultSplashDone() {
    setState(() => _state = _GateState.onboarding);
  }

  void _onRoleSplashDone() {
    setState(() => _state = _GateState.home);
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _GateState.booting:
        return const Scaffold(
          backgroundColor: CG.bg,
          body: Center(
            child: CircularProgressIndicator(color: CG.primary),
          ),
        );

      case _GateState.defaultSplash:
        return DefaultSplash(onDone: _onDefaultSplashDone);

      case _GateState.roleSplash:
        return roleSplash(_role!, _onRoleSplashDone);

      case _GateState.home:
        final user = AuthStore.instance.currentUser;
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _decide();
          });
          return const SizedBox.shrink();
        }
        switch (user.role) {
          case UserRole.patient:
            return Shell(store: widget.store);
          case UserRole.caregiver:
            return CaregiverShell(store: widget.store);
          case UserRole.family:
            return FamilyShell(store: widget.store);
        }

      case _GateState.onboarding:
        return PreHomeRouter(store: widget.store);
    }
  }
}