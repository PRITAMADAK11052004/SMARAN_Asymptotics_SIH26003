import 'package:flutter/material.dart';

import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_store.dart';
import '../../core/auth/pre_home_state.dart';
import '../../core/theme/caregiver_theme.dart';

class RegistrationScreen extends StatefulWidget {
  final UserRole role;
  const RegistrationScreen({super.key, required this.role});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _age = TextEditingController();
  final _education = TextEditingController();
  final _relationship = TextEditingController();
  final _password = TextEditingController();

  DateTime? _dob;
  bool _busy = false;
  String? _error;

  bool get _isPatient => widget.role == UserRole.patient;
  bool get _isCaregiver => widget.role == UserRole.caregiver;
  bool get _isFamily => widget.role == UserRole.family;

  String get _title => switch (widget.role) {
        UserRole.patient => 'Create Patient Account',
        UserRole.caregiver => 'Create Caregiver Account',
        UserRole.family => 'Create Family Account',
      };

  String get _subtitle => switch (widget.role) {
        UserRole.patient =>
          'A caregiver will help you through this setup.',
        UserRole.caregiver =>
          'Your details help us tailor care for your patient.',
        UserRole.family =>
          'Stay close to your loved one, wherever you are.',
      };

  IconData get _roleIcon => switch (widget.role) {
        UserRole.patient => Icons.person_rounded,
        UserRole.caregiver => Icons.medical_services_rounded,
        UserRole.family => Icons.groups_rounded,
      };

  Color get _roleAccent => switch (widget.role) {
        UserRole.patient => const Color(0xFFE5F0D8),
        UserRole.caregiver => const Color(0xFFF5E6C7),
        UserRole.family => const Color(0xFFF6DCDD),
      };

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _age.dispose();
    _education.dispose();
    _relationship.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 65),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: CG.danger),
    );
  }

  /// Returns to the Login screen for the same role.
  Future<void> _backToLogin() async {
    await AuthStore.instance.setPhase(OnboardingPhase.login);
    // Router rebuilds → LoginScreen(role).
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final password = _password.text.trim();

    if (name.isEmpty) return _toast('Please enter your full name.');
    if (phone.isEmpty) return _toast('Please enter your mobile number.');
    if (password.length < 4) {
      return _toast('Password must be at least 4 characters.');
    }
    if (_isPatient && _dob == null) {
      return _toast('Please select your date of birth.');
    }
    if (_isFamily && _relationship.text.trim().isEmpty) {
      return _toast('Please enter your relationship to the patient.');
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await AuthStore.instance.register(
        fullName: name,
        email: email,
        phone: phone,
        password: password,
        role: widget.role,
        dateOfBirth: _dob,
        relationship: _isFamily ? _relationship.text.trim() : null,
      );

      await AuthStore.instance.setPhase(OnboardingPhase.otpMethod);
      // Router rebuilds → OtpMethodScreen.
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CG.bg,
      appBar: AppBar(
        backgroundColor: CG.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: CG.primary),
          onPressed: _backToLogin,
        ),
        title: Text(
          _title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: CG.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: _roleAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_roleIcon, color: CG.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CG.textMuted,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              _field('Full Name', Icons.person_outline_rounded, _name,
                  cap: TextCapitalization.words),

              if (_isPatient) ...[
                const SizedBox(height: 14),
                _dobPicker(),
              ],

              const SizedBox(height: 14),
              _field('Mobile Number', Icons.phone_outlined, _phone,
                  keyboard: TextInputType.phone),

              const SizedBox(height: 14),
              _field('Email Address', Icons.email_outlined, _email,
                  keyboard: TextInputType.emailAddress, hint: 'Optional'),

              if (_isCaregiver) ...[
                const SizedBox(height: 14),
                _field('Age', Icons.cake_outlined, _age,
                    keyboard: TextInputType.number, hint: 'Optional'),
                const SizedBox(height: 14),
                _field('Education Qualification',
                    Icons.school_outlined, _education,
                    hint: 'Optional'),
              ],

              if (_isFamily) ...[
                const SizedBox(height: 14),
                _field('Your Relationship to Patient',
                    Icons.favorite_outline_rounded, _relationship,
                    cap: TextCapitalization.words,
                    hint: 'e.g. Daughter, Son, Spouse'),
              ],

              const SizedBox(height: 14),
              _field('Password', Icons.lock_outline_rounded, _password,
                  obscure: true),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFADCDC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: CG.danger.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: CG.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                fontSize: 12.5,
                                color: CG.danger,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
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
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'We will send a one-time code to verify your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: CG.textFaint),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CG.border),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Already have an account?',
                        style: TextStyle(
                          fontSize: 13,
                          color: CG.textMuted,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _backToLogin,
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: CG.primary,
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

  Widget _dobPicker() {
    final hasDate = _dob != null;
    return InkWell(
      onTap: _pickDob,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CG.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_rounded,
                color: CG.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasDate
                    ? '${_dob!.day} ${_monthName(_dob!.month)} ${_dob!.year}'
                    : 'Date of Birth',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: hasDate ? CG.textPrimary : CG.textMuted,
                ),
              ),
            ),
            const Icon(Icons.calendar_month_rounded,
                color: CG.textFaint, size: 20),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];

  Widget _field(
    String label,
    IconData icon,
    TextEditingController ctrl, {
    TextInputType? keyboard,
    TextCapitalization cap = TextCapitalization.none,
    bool obscure = false,
    String? hint,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      textCapitalization: cap,
      obscureText: obscure,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: CG.primary, size: 22),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: CG.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: CG.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: CG.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}