import 'package:flutter/material.dart';

import '../../core/auth/auth_store.dart';
import '../../core/theme/caregiver_theme.dart';

class FamilySettingsScreen extends StatelessWidget {
  const FamilySettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: CG.primary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: CG.danger),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthStore.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: CG.primary)),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CG.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: CG.primarySoft,
                  child: Text(
                    (user?.fullName.isNotEmpty ?? false)
                        ? user!.fullName[0].toUpperCase()
                        : 'F',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: CG.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? 'Family Member',
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: CG.textPrimary)),
                      Text(user?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11.5, color: CG.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _group('Preferences', [
            _tile(Icons.language_rounded, 'Language',
                trailing: 'English'),
            _tile(Icons.notifications_rounded, 'Notifications'),
            _tile(Icons.accessibility_new_rounded, 'Accessibility'),
          ]),

          _group('Privacy & Security', [
            _tile(Icons.lock_rounded, 'Privacy & Security'),
          ]),

          const SizedBox(height: 16),

          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded,
                  color: CG.danger, size: 20),
              label: const Text('Log Out',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: CG.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: CG.danger, width: 1.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(String label, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900,
                  color: CG.primary),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CG.border),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, {String? trailing}) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: CG.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: CG.textPrimary)),
            ),
            if (trailing != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CG.primaryPale,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(trailing,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: CG.primary)),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: CG.textFaint, size: 22),
          ],
        ),
      ),
    );
  }
}