import 'package:flutter/material.dart';

import '../../core/auth/auth_store.dart';
import '../../core/auth/pre_home_state.dart';
import '../../core/theme/caregiver_theme.dart';
import '../../core/widgets/smaran_id_card.dart';

class SmrnRevealScreen extends StatelessWidget {
  const SmrnRevealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.instance.currentUser;
    final smrn = user?.patientId ?? 'SMRN-XXXX-XXXX';
    final firstName = user?.fullName.split(' ').first ?? 'there';

    return Scaffold(
      backgroundColor: CG.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Green success badge
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
              const SizedBox(height: 22),

              const Text(
                "You're Verified!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: CG.primary,
                ),
              ),
              const SizedBox(height: 12),

              // ⭐ Big, bold Welcome, Name
              Text(
                'Welcome, $firstName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: CG.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your identity has been confirmed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: CG.textMuted),
              ),
              const SizedBox(height: 28),

              // ⭐ QR visible by default — tap to flip to ID
              SmaranIdCard(smrnId: smrn, size: 240, startWithQr: true),

              const SizedBox(height: 20),

              // ID text below as a secondary info card
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CG.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: CG.primaryPale,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_rounded,
                          color: CG.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Smaran ID',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: CG.textMuted,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            smrn,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: CG.primary,
                              letterSpacing: 1.2,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                'You can view this QR from your profile anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: CG.textFaint),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () async {
                    // Let RootGate handle the splash + Home transition.
                    await AuthStore.instance
                        .setPhase(OnboardingPhase.home);
                  },
                  icon: const Icon(Icons.home_rounded, size: 22),
                  label: const Text(
                    'Continue to Home',
                    style: TextStyle(
                      fontSize: 16,
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
            ],
          ),
        ),
      ),
    );
  }
}