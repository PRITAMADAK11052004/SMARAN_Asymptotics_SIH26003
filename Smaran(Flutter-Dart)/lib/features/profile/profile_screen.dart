import 'package:flutter/material.dart';

import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_store.dart';
import '../../core/localization/app_languages.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/patient_avatar.dart';
import '../../core/widgets/smaran_id_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: cDeep)),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: cDanger),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await AuthStore.instance.logout();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
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

    final smrn = user.patientId ?? 'SMRN-XXXX-XXXX';

    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: cDeep,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            children: [
              // Face photo (or initial fallback)
              PatientAvatar(
                user: user,
                fallbackName: user.fullName,
                size: 110,
                borderColor: cPrimaryDark,
                onTap: user.facePhotoBase64 != null
                    ? () => showPatientPhotoViewer(
                          context,
                          base64Jpeg: user.facePhotoBase64!,
                          patientName: user.fullName,
                        )
                    : null,
              ),
              const SizedBox(height: 14),
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
                    horizontal: 12, vertical: 5),
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

              const SizedBox(height: 24),

              // ⭐ QR + ID
              if (user.role == UserRole.patient) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SMRAN ID',
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w900,
                      color: cPrimaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SmaranIdCard(smrnId: smrn, size: 240, startWithQr: true),
                const SizedBox(height: 20),
              ],

              // Account details
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'ACCOUNT',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w900,
                    color: cPrimaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: cWhite,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cBorder),
                ),
                child: Column(
                  children: [
                    _row(Icons.email_outlined, 'Email',
                        user.email.isEmpty ? '—' : user.email),
                    const Divider(height: 1, color: cBorder),
                    _row(Icons.phone_outlined, 'Phone',
                        user.phone.isEmpty ? '—' : user.phone),
                    const Divider(height: 1, color: cBorder),
                    _row(Icons.language_rounded, 'Language',
                        user.preferredLanguage.englishName),
                    const Divider(height: 1, color: cBorder),
                    _row(
                      Icons.verified_user_outlined,
                      'Account status',
                      user.verified ? 'Verified' : 'Pending',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 54,
                width: double.infinity,
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
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: cPrimaryDark),
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