import 'package:flutter/material.dart';

import '../../core/auth/auth_store.dart';
import '../../core/auth/pre_home_state.dart';
import '../../core/theme/caregiver_theme.dart';

class OtpMethodScreen extends StatefulWidget {
  const OtpMethodScreen({super.key});

  @override
  State<OtpMethodScreen> createState() => _OtpMethodScreenState();
}

class _OtpMethodScreenState extends State<OtpMethodScreen> {
  String _method = 'sms';
  bool _busy = false;

  Future<void> _continue() async {
    setState(() => _busy = true);

    await AuthStore.instance.setOtpMethod(_method);
    await AuthStore.instance.setPhase(OnboardingPhase.otpEntry);

    // Trigger OTP issue (mock backend — DEV OTP visible on next screen).
    try {
      await AuthStore.instance.resendOtp();
    } catch (_) {
      // First-time registration may not have a prior OTP record.
    }

    if (!mounted) return;
    setState(() => _busy = false);
    // Router rebuilds → OtpEntryScreen.
  }

  Future<void> _back() async {
    await AuthStore.instance.setPhase(OnboardingPhase.registration);
    // Router rebuilds → RegistrationScreen(role).
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.instance.currentUser;

    return Scaffold(
      backgroundColor: CG.bg,
      appBar: AppBar(
        backgroundColor: CG.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: CG.primary),
          onPressed: _back,
        ),
        title: const Text(
          'Verify Your Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: CG.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Choose OTP Method',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: CG.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We will send a 6-digit code to confirm this is you.',
                style: TextStyle(
                  fontSize: 13,
                  color: CG.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              _option(
                id: 'sms',
                icon: Icons.sms_rounded,
                label: 'SMS',
                subtitle: (user?.phone.isNotEmpty ?? false)
                    ? user!.phone
                    : 'Mobile number',
              ),
              const SizedBox(height: 12),
              _option(
                id: 'email',
                icon: Icons.email_rounded,
                label: 'Email',
                subtitle: (user?.email.isNotEmpty ?? false)
                    ? user!.email
                    : 'Email address',
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _busy ? null : _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: CG.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Send Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
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

  Widget _option({
    required String id,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final selected = _method == id;
    return GestureDetector(
      onTap: () => setState(() => _method = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? CG.primary : CG.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? CG.primaryPale : CG.cardSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon,
                  color: selected ? CG.primary : CG.textMuted,
                  size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: CG.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: CG.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? CG.primary : CG.border,
                  width: 2,
                ),
                color: selected ? CG.primary : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}