import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_store.dart';
import '../../core/theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _contact = TextEditingController();
  final _newPassword = TextEditingController();
  final _otp = TextEditingController();
  bool _busy = false;
  String? _userId;
  String? _error;

  @override
  void dispose() {
    _contact.dispose();
    _newPassword.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final contact = _contact.text.trim();
    if (contact.isEmpty) {
      setState(() => _error = 'Enter your email or mobile number.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final uid = await AuthStore.instance.startPasswordReset(contact);
      if (uid == '__no_user__') {
        setState(() => _error = 'No account found for that contact.');
        return;
      }
      setState(() => _userId = uid);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final uid = _userId;
    if (uid == null) return;
    if (_otp.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP.');
      return;
    }
    if (_newPassword.text.trim().length < 4) {
      setState(() => _error = 'Password must be at least 4 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.verifyOtp(
        userId: uid,
        code: _otp.text.trim(),
      );
      await AuthStore.instance.completePasswordReset(
        userId: uid,
        newPassword: _newPassword.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset. Please log in.'),
          backgroundColor: cPrimaryDark,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final devOtp = AuthService.instance.debugLastOtp;
    final step1 = _userId == null;

    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: cDeep),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: cDeep,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Icon(
                step1 ? Icons.lock_reset_rounded : Icons.verified_rounded,
                color: cPrimaryDark,
                size: 54,
              ),
              const SizedBox(height: 12),
              Text(
                step1
                    ? 'Enter your email or mobile number'
                    : 'Enter the OTP and your new password',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: cText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),

              if (step1)
                TextField(
                  controller: _contact,
                  decoration: inputDec('Email or mobile number'),
                )
              else ...[
                if (devOtp != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4D6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFE8B84C), width: 1.2),
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
                              const Text('DEV MODE — OTP',
                                  style: TextStyle(
                                      fontSize: 10,
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF8A6212))),
                              SelectableText(devOtp,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      letterSpacing: 4,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF4A3503))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration:
                      inputDec('6-digit OTP').copyWith(counterText: ''),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPassword,
                  obscureText: true,
                  decoration: inputDec('New password'),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(
                        color: cDanger,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
              ],

              const SizedBox(height: 20),
              primaryButton(
                step1 ? 'Send OTP' : 'Reset Password',
                _busy ? null : (step1 ? _sendOtp : _resetPassword),
                icon: step1
                    ? Icons.send_rounded
                    : Icons.check_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}