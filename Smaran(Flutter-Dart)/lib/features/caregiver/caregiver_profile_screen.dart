import 'package:flutter/material.dart';

import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_store.dart';
import '../../core/localization/app_languages.dart';
import '../../core/theme/app_theme.dart';

class CaregiverProfileScreen extends StatefulWidget {
  const CaregiverProfileScreen({super.key});

  @override
  State<CaregiverProfileScreen> createState() =>
      _CaregiverProfileScreenState();
}

class _CaregiverProfileScreenState extends State<CaregiverProfileScreen> {
  @override
  void initState() {
    super.initState();
    AuthStore.instance.addListener(_rebuild);
  }

  @override
  void dispose() {
    AuthStore.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  // ── Edit profile with OTP ───────────────────────────────────
  Future<void> _editProfile() async {
    final user = AuthStore.instance.currentUser;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phone);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: cDeep,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'An OTP will be sent to confirm your changes.',
                style: TextStyle(fontSize: 12.5, color: cMuted),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: nameCtrl,
                decoration: inputDec('Full name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: inputDec('Phone number'),
              ),
              const SizedBox(height: 20),
              primaryButton(
                'Save Changes',
                () => Navigator.pop(context, true),
                icon: Icons.check_rounded,
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    // Trigger OTP for this user.
    try {
      await AuthService.instance.resendOtp(user.id);
    } catch (_) {
      // Ignore — first-time use may have no prior OTP.
    }

    if (!mounted) return;

    // Show OTP verification dialog.
    final code = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _OtpDialog(),
    );

    if (code == null || !mounted) return;

    // Verify.
    try {
      await AuthService.instance.verifyOtp(userId: user.id, code: code);
      final updated = user.copyWith(
        fullName: nameCtrl.text.trim().isEmpty
            ? user.fullName
            : nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim().isEmpty
            ? user.phone
            : phoneCtrl.text.trim(),
        updatedAt: DateTime.now(),
      );
      await AuthStore.instance.updateCurrentUser(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated.'),
            backgroundColor: cPrimaryDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save: $e'),
            backgroundColor: cDanger,
          ),
        );
      }
    }
  }

  // ── Logout ──────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Log out?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: cDeep,
          ),
        ),
        content: const Text(
          'You will need to sign in again to access your patients.',
          style: TextStyle(fontSize: 14, height: 1.5, color: cText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: cDanger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await AuthStore.instance.logout();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: cBg,
        body: Center(child: CircularProgressIndicator(color: cPrimary)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: cSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              user.fullName.isNotEmpty
                  ? user.fullName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: cPrimaryDark,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: cDeep,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: cSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.role.englishLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: cPrimaryDark,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Info card
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cBorder),
            ),
            child: Column(
              children: [
                _Row(icon: Icons.email_outlined, label: 'Email',
                    value: user.email.isEmpty ? '—' : user.email),
                const Divider(height: 1, color: cBorder),
                _Row(icon: Icons.phone_outlined, label: 'Phone',
                    value: user.phone.isEmpty ? '—' : user.phone),
                const Divider(height: 1, color: cBorder),
                _Row(icon: Icons.language_rounded, label: 'Language',
                    value: user.preferredLanguage.englishName),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Edit button
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit_rounded,
                  color: cPrimaryDark, size: 22),
              label: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: cPrimaryDark,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: cPrimaryDark, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Logout button
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded,
                  color: cDanger, size: 22),
              label: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: cDanger,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: cDanger, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: cPrimaryDark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: cMuted,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 13.5,
                          color: cText,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      );
}

// =============================================================================
// OTP dialog (DEV mode — shows OTP on screen)
// =============================================================================

class _OtpDialog extends StatefulWidget {
  const _OtpDialog();

  @override
  State<_OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<_OtpDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devOtp = AuthService.instance.debugLastOtp;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Enter OTP',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (devOtp != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4D6),
                borderRadius: BorderRadius.circular(12),
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
                        const SizedBox(height: 2),
                        SelectableText(
                          devOtp,
                          style: const TextStyle(
                            fontSize: 20,
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
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: inputDec('6-digit code').copyWith(
              counterText: '',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: const Text('Verify'),
        ),
      ],
    );
  }
}