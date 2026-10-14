import 'package:flutter/material.dart';

import '../../core/auth/auth_store.dart';
import '../../core/domain/app_models.dart';
import '../../core/theme/caregiver_theme.dart';
import 'family_circle_screen.dart';
import 'family_help_screen.dart';
import 'family_home_screen.dart';
import 'family_memories_screen.dart';
import 'family_notifications_screen.dart';
import 'family_patient_profile_screen.dart';
import 'family_progress_screen.dart';
import 'family_routine_screen.dart';
import 'family_settings_screen.dart';

class FamilyShell extends StatefulWidget {
  final SmaranStore store;
  const FamilyShell({super.key, required this.store});

  @override
  State<FamilyShell> createState() => _FamilyShellState();
}

class _FamilyShellState extends State<FamilyShell> {
  int _tabIndex = 0;

  static const _menuItems = [
    _MenuItem('Home', Icons.home_rounded),
    _MenuItem('Patient Profile', Icons.person_rounded),
    _MenuItem('Memories', Icons.photo_library_rounded),
    _MenuItem('Daily Routine', Icons.checklist_rounded),
    _MenuItem('Progress & Insights', Icons.trending_up_rounded),
    _MenuItem('Family Circle', Icons.groups_rounded),
    _MenuItem('Notifications', Icons.notifications_rounded),
    _MenuItem('Settings', Icons.settings_rounded),
    _MenuItem('Help & Support', Icons.help_outline_rounded),
  ];

  void _go(int index) {
    setState(() => _tabIndex = index);
    if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      FamilyHomeScreen(store: widget.store, onNavigate: _go),
      FamilyPatientProfileScreen(store: widget.store),
      FamilyMemoriesScreen(store: widget.store),
      FamilyRoutineScreen(store: widget.store),
      FamilyProgressScreen(store: widget.store),
      FamilyCircleScreen(store: widget.store),
      FamilyNotificationsScreen(store: widget.store),
      const FamilySettingsScreen(),
      const FamilyHelpScreen(),
    ];

    return Scaffold(
      backgroundColor: CG.bg,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: IndexedStack(index: _tabIndex, children: pages),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final user = AuthStore.instance.currentUser;
    final initial = (user?.fullName.isNotEmpty ?? false)
        ? user!.fullName[0].toUpperCase()
        : 'F';

    return AppBar(
      backgroundColor: CG.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: CG.primary),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 34,
            height: 34,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          const Text(
            'Smaran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: CG.primary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded,
              color: CG.primary),
          onPressed: () => _go(6),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    user?.fullName ?? 'Family',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: CG.primary,
                    ),
                  ),
                  const Text('Family Member',
                      style: TextStyle(
                          fontSize: 10, color: CG.textMuted)),
                ],
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 17,
                backgroundColor: CG.primarySoft,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: CG.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: CG.bg,
      width: 260,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 42,
                    height: 42,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Smaran',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: CG.primary,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: CG.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: List.generate(_menuItems.length, (i) {
                  final item = _menuItems[i];
                  return _DrawerTile(
                    icon: item.icon,
                    label: item.label,
                    selected: _tabIndex == i,
                    onTap: () => _go(i),
                  );
                }),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: CG.border)),
              ),
              child: Builder(
                builder: (tileCtx) => InkWell(
                  onTap: () async {
                    await AuthStore.instance.logout();
                    if (tileCtx.mounted) {
                      Navigator.of(tileCtx)
                          .popUntil((r) => r.isFirst);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: const [
                        Icon(Icons.logout_rounded,
                            color: CG.danger, size: 22),
                        SizedBox(width: 14),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: CG.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  const _MenuItem(this.label, this.icon);
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? CG.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon,
                    size: 22,
                    color: selected ? CG.primary : CG.textMuted),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected
                          ? FontWeight.w900
                          : FontWeight.w700,
                      color:
                          selected ? CG.primary : CG.textPrimary,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: CG.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}