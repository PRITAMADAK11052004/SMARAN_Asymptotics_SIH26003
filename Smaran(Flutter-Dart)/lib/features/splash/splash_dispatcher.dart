import 'package:flutter/material.dart';

import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_store.dart';
import '../../core/domain/app_models.dart';
import '../caregiver/caregiver_shell.dart';
import '../family/family_shell.dart';
import '../shell/shell.dart';
import 'role_splashes.dart';

/// Shown when a returning user with a valid session opens the app.
/// Plays the role-specific splash then routes to the correct Home shell.
class SplashDispatcher extends StatelessWidget {
  final SmaranStore store;
  const SplashDispatcher({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.instance.currentUser;
    if (user == null) {
      return const DefaultSplash(onDone: _noop);
    }

    return roleSplash(user.role, () {
      if (!context.mounted) return;

      Widget next;
      switch (user.role) {
        case UserRole.patient:
          next = Shell(store: store);
        case UserRole.caregiver:
          next = CaregiverShell(store: store);
        case UserRole.family:
          next = FamilyShell(store: store);
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => next),
      );
    });
  }

  static void _noop() {}
}