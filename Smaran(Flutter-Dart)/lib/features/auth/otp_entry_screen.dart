import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_store.dart';
import '../../core/auth/pre_home_state.dart';
import '../../core/theme/caregiver_theme.dart';

class OtpEntryScreen extends StatefulWidget {
  const OtpEntryScreen({super.key});

  @override
  State<OtpEntryScreen> createState() => _OtpEntryScreenState();
}

class _OtpEntryScreenState extends State<OtpEntryScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _ctrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final ok = await AuthStore.instance.verifyOtp(code: code);
      if (!ok) {
        setState(() => _error = 'That code is not correct.');
        return;
      }

      final user = AuthStore.instance.currentUser;
      if (user == null) {
        setState(() => _error = 'Account not found.');
        return;
      }

      if (user.role == UserRole.patient) {
        await AuthStore.instance.setPhase(OnboardingPhase.faceSetup);
      } else {
        await AuthStore.instance.setPhase(OnboardingPhase.linkPrompt);
      }
      // Router rebuilds → FaceEnrollmentScreen or LinkPromptScreen.
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      await AuthStore.instance.resendOtp();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New code sent.'),
          backgroundColor: CG.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: CG.danger,
        ),
      );
    }
  }

  Future<void> _back() async {
    await AuthStore.instance.setPhase(OnboardingPhase.otpMethod);
    // Router rebuilds → OtpMethodScreen.
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.instance.currentUser;
    final method = AuthStore.instance.otpMethod;
    final target = method == 'sms'
        ? ((user?.phone.isNotEmpty ?? false) ? user!.phone : 'your phone')
        : ((user?.email.isNotEmpty ?? false) ? user!.email : 'your email');
    final devOtp = AuthService.instance.debugLastOtp;

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
          'Enter OTP',
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
                'Verify Your Number',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: CG.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to $target.',
                style: const TextStyle(
                  fontSize: 13,
                  color: CG.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              if (devOtp != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4D6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE8B84C),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.construction_rounded,
                          color: Color(0xFF8A6212), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DEV MODE — OTP',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF8A6212),
                              ),
                            ),
                            SelectableText(
                              devOtp,
                              style: const TextStyle(
                                fontSize: 22,
                                letterSpacing: 4,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4A3503),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              TextField(
                controller: _ctrl,
                focusNode: _focus,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  letterSpacing: 12,
                  fontWeight: FontWeight.w900,
                  color: CG.primary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  hintStyle: TextStyle(
                    fontSize: 30,
                    letterSpacing: 12,
                    color: CG.textFaint.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: CG.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: CG.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide:
                        const BorderSide(color: CG.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 24, horizontal: 16),
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _verify(),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CG.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],

              const SizedBox(height: 28),

              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _busy ? null : _verify,
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
                          'Verify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: _resend,
                child: const Text(
                  'Resend Code',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: CG.primary,
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