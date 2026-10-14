import 'package:flutter/material.dart';

import '../../core/auth/auth_store.dart';
import '../../core/domain/app_models.dart';
import '../../core/theme/caregiver_theme.dart';
import 'caregiver_alerts_screen.dart';
import 'caregiver_home_screen.dart';
import 'caregiver_memory_bank_screen.dart';
import 'caregiver_my_patients_screen.dart';
import 'caregiver_patient_profile_screen.dart';
import 'caregiver_progress_screen.dart';
import 'caregiver_reports_screen.dart';
import 'caregiver_settings_screen.dart';

class CaregiverShell extends StatefulWidget {
  final SmaranStore store;
  const CaregiverShell({super.key, required this.store});

  @override
  State<CaregiverShell> createState() => _CaregiverShellState();
}

class _CaregiverShellState extends State<CaregiverShell> {
  int _tabIndex = 0;

  // Tab indices — keep in sync with `_menuItems` and `_pages`.

  static const tabPatientProfile = 2;
  static const tabAlerts = 4;

  static const _menuItems = [
    _MenuItem('Home', Icons.home_rounded),
    _MenuItem('My Patients', Icons.groups_rounded),
    _MenuItem('Patient Profile', Icons.person_rounded),
    _MenuItem('Progress', Icons.trending_up_rounded),
    _MenuItem('Alerts', Icons.notifications_rounded),
    _MenuItem('Memory Bank', Icons.photo_library_rounded),
    _MenuItem('Reports', Icons.description_rounded),
    _MenuItem('Settings', Icons.settings_rounded),
  ];

  void _go(int index) {
    setState(() => _tabIndex = index);
    if (Scaffold.of(context).isDrawerOpen) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      CaregiverHomeScreen(store: widget.store, onNavigate: _go),
      CaregiverMyPatientsScreen(
        store: widget.store,
        onOpenProfile: () => _go(tabPatientProfile),
      ),
      CaregiverPatientProfileScreen(store: widget.store),
      CaregiverProgressScreen(store: widget.store),
      CaregiverAlertsScreen(store: widget.store),
      CaregiverMemoryBankScreen(store: widget.store),
      CaregiverReportsScreen(store: widget.store),
      const CaregiverSettingsScreen(),
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
        : 'C';

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
          onPressed: () => _go(tabAlerts),
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
                    user?.fullName ?? 'Caregiver',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: CG.primary,
                    ),
                  ),
                  const Text('Caregiver',
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
                children:
                    List.generate(_menuItems.length, (i) {
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
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: CG.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: CG.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: CG.primary,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Last sync: 2 min ago',
                    style:
                        TextStyle(fontSize: 10.5, color: CG.textMuted),
                  ),
                ],
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
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        selected ? FontWeight.w900 : FontWeight.w700,
                    color: selected ? CG.primary : CG.textPrimary,
                  ),
                ),
                if (selected) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: CG.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}