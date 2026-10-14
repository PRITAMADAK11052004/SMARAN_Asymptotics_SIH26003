import 'package:flutter/material.dart';

import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_store.dart';
import '../../core/auth/pre_home_state.dart';
import '../../core/theme/caregiver_theme.dart';
import 'link_patient_screen.dart';

class LinkPromptScreen extends StatelessWidget {
  const LinkPromptScreen({super.key});

  Future<void> _skip() async {
    await AuthStore.instance.setPhase(OnboardingPhase.home);
  }

  Future<void> _openLink(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LinkPatientScreen(showBackButton: true),
      ),
    );
    // After the link screen returns, if the caregiver linked at least one
    // patient OR chose skip, move to home.
    final linked = AuthStore.instance.linkedPatients;
    if (linked.isNotEmpty) {
      await AuthStore.instance.setPhase(OnboardingPhase.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.instance.currentUser;
    final isFamily = user?.role == UserRole.family;
    final body = isFamily
        ? 'Connect with your loved one to see how they are doing.'
        : 'Connect with the patient you care for. You can also do this later.';

    return Scaffold(
      backgroundColor: CG.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: CG.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 42),
              ),
              const SizedBox(height: 16),
              const Text(
                'Account Created!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: CG.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: CG.textMuted,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              _Option(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan Patient QR',
                subtitle: "Use the camera to scan the patient's QR code.",
                onTap: () => _openLink(context),
              ),
              const SizedBox(height: 12),
              _Option(
                icon: Icons.keyboard_rounded,
                title: 'Enter Smaran ID Manually',
                subtitle: 'Type the SMRN-XXXX-XXXX code from the patient.',
                onTap: () => _openLink(context),
              ),
              const SizedBox(height: 12),
              _Option(
                icon: Icons.schedule_rounded,
                title: 'Skip for Now',
                subtitle: 'You can link a patient later from the menu.',
                onTap: _skip,
              ),
              const Spacer(),
              const Text(
                'You can add or change patient links anytime.',
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

class _Option extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CG.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: CG.primaryPale,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: CG.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: CG.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: CG.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: CG.textFaint, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}