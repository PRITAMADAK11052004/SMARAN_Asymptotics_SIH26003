import 'package:flutter/material.dart';

import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_store.dart';
import '../../core/auth/pre_home_state.dart';
import '../../core/theme/app_theme.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final UserRole role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _contact = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _contact.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final contact = _contact.text.trim();
    final pw = _password.text.trim();
    if (contact.isEmpty || pw.isEmpty) {
      setState(() => _error = 'Enter your email/mobile and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthStore.instance.login(contact: contact, password: pw);
      await AuthStore.instance.setPhase(OnboardingPhase.home);
      // RootGate detects isLoggedIn + phase==home and shows role splash → Home.
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _goToRegister() async {
    await AuthStore.instance.setPendingRole(widget.role);
    await AuthStore.instance.setPhase(OnboardingPhase.registration);
    // Router rebuilds → RegistrationScreen(role).
  }

  Future<void> _back() async {
    await AuthStore.instance.setPendingRole(null);
    await AuthStore.instance.setPhase(OnboardingPhase.none);
    // Router rebuilds → RoleSelectionScreen.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: cDeep),
          onPressed: _back,
        ),
        title: const Text(
          'Log In',
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
              const SizedBox(height: 16),
              const Center(child: Logo(size: 72)),
              const SizedBox(height: 20),
              Text(
                'Welcome back, ${widget.role.englishLabel}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: cDeep,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Log in to continue',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cMuted),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _contact,
                keyboardType: TextInputType.emailAddress,
                decoration: inputDec('Email or mobile number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: inputDec('Password'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: cDanger,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              primaryButton(
                'Log In',
                _busy ? null : _login,
                icon: Icons.login_rounded,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: cPrimaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cBorder),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "New to Smaran?",
                        style: TextStyle(fontSize: 13, color: cMuted),
                      ),
                    ),
                    TextButton(
                      onPressed: _goToRegister,
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: cPrimaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}