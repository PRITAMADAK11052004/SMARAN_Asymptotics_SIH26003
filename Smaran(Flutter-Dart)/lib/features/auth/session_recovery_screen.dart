import 'package:flutter/material.dart';
import '../../core/auth/auth_store.dart';
import '../../core/auth/pre_home_state.dart';
import '../../core/theme/caregiver_theme.dart';

class SessionRecoveryScreen extends StatefulWidget {
  const SessionRecoveryScreen({super.key});

  @override
  State<SessionRecoveryScreen> createState() =>
      _SessionRecoveryScreenState();
}

class _SessionRecoveryScreenState extends State<SessionRecoveryScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _recover() async {
    final last = AuthStore.instance.lastKnownUser;
    if (last == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // Re-authenticate and issue a fresh session.
      // In production this would trigger biometric or OTP verification.
      // Simulate a mini-login so AuthStore updates state correctly.
      // We re-issue session manually:
      await AuthStore.instance.login(
        contact: last.email.isNotEmpty ? last.email : last.phone,
        password: 'recover',
      );
      if (!mounted) return;
      // Router will detect isLoggedIn and route to the correct Home.
    } catch (e) {
      setState(() => _error = 'Please verify your account to continue.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = AuthStore.instance.lastKnownUser;
    final name = last?.fullName ?? 'there';

    return Scaffold(
      backgroundColor: CG.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: CG.primaryPale,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_clock_rounded,
                    color: CG.primary, size: 48),
              ),
              const SizedBox(height: 22),
              const Text('Session Expired',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: CG.primary)),
              const SizedBox(height: 8),
              Text(
                'Welcome back, $name. Please verify your account to continue.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13.5,
                    color: CG.textMuted,
                    height: 1.55),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: CG.danger,
                        fontWeight: FontWeight.w700)),
              ],
              const Spacer(),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _recover,
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
                      : const Text('Verify Account',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await AuthStore.instance.logout();
                  await AuthStore.instance.setPhase(
                      OnboardingPhase.none);
                  await AuthStore.instance.setPendingRole(null);
                },
                child: const Text('Use a different account',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: CG.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}