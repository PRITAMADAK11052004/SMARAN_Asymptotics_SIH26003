import 'package:flutter/material.dart';

import '../../core/auth/auth_store.dart';
import '../../core/domain/app_models.dart';
import '../../core/services/caregiver_analytics.dart';
import '../../core/theme/caregiver_theme.dart';

class FamilyHomeScreen extends StatefulWidget {
  final SmaranStore store;
  final void Function(int) onNavigate;
  const FamilyHomeScreen({
    super.key,
    required this.store,
    required this.onNavigate,
  });

  @override
  State<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends State<FamilyHomeScreen> {
  @override
  void initState() {
    super.initState();
    AuthStore.instance.addListener(_rebuild);
    widget.store.addListener(_rebuild);
  }

  @override
  void dispose() {
    AuthStore.instance.removeListener(_rebuild);
    widget.store.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final user = AuthStore.instance.currentUser;
    final patients = AuthStore.instance.linkedPatients;
    final patient = patients.isNotEmpty ? patients.first : null;

    final (medsDue, medsTotal) =
        CaregiverAnalytics.remindersToday(store);
    final memoriesNew = store.memories.length;
    final (routinePending, routineTotal) = _routineStats(store);
    final activitiesToday =
        CaregiverAnalytics.gamesPlayedToday(store);

    final firstName = user?.fullName.split(' ').first ?? 'there';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${_greeting()}, $firstName!',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: CG.primary,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.wb_sunny_rounded,
                            color: Color(0xFFE49A1E), size: 22),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Here is how your loved one is doing.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: CG.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (patient != null)
            _PatientHeroCard(
              name: patient.fullName,
              relation: patient.relationship ?? 'Family',
              onViewProfile: () => widget.onNavigate(1),
            )
          else
            _NoPatientCard(),

          const SizedBox(height: 20),

          const _SectionLabel('TODAY AT A GLANCE'),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _GlanceTile(
                  icon: Icons.medication_rounded,
                  title: 'Medications',
                  value: '$medsDue due today',
                  sub: '$medsTotal total',
                  bg: CG.medicineBg,
                  fg: CG.medicineFg,
                  onTap: () => widget.onNavigate(7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GlanceTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Memories',
                  value: '$memoriesNew new',
                  sub: 'in memory bank',
                  bg: CG.gamesBg,
                  fg: CG.gamesFg,
                  onTap: () => widget.onNavigate(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _GlanceTile(
                  icon: Icons.checklist_rounded,
                  title: 'Daily Routine',
                  value: '$routinePending pending',
                  sub: 'of $routineTotal tasks',
                  bg: CG.hydrationBg,
                  fg: CG.hydrationFg,
                  onTap: () => widget.onNavigate(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GlanceTile(
                  icon: Icons.favorite_rounded,
                  title: 'Activities',
                  value: '$activitiesToday today',
                  sub: 'games played',
                  bg: CG.moodBg,
                  fg: CG.moodFg,
                  onTap: () => widget.onNavigate(4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Quick contributions card
          _ContributeCard(
            onAddMemory: () => widget.onNavigate(2),
            onAddRoutine: () => widget.onNavigate(3),
          ),

          const SizedBox(height: 22),

          // Encouragement footer
          const _FooterMessage(),
        ],
      ),
    );
  }

  (int pending, int total) _routineStats(SmaranStore store) {
    final reminders = store.reminders;
    final total = reminders.length;
    final done = reminders.where((r) => r.done).length;
    return (total - done, total);
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
            color: CG.primary,
          ),
        ),
      );
}

class _PatientHeroCard extends StatelessWidget {
  final String name;
  final String relation;
  final VoidCallback onViewProfile;

  const _PatientHeroCard({
    required this.name,
    required this.relation,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CG.rCard),
        border: Border.all(color: CG.border),
        boxShadow: CG.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: CG.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: CG.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: CG.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  relation,
                  style: const TextStyle(
                      fontSize: 12, color: CG.textMuted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onViewProfile,
            style: TextButton.styleFrom(
              foregroundColor: CG.primary,
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View Profile',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPatientCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CG.rCard),
        border: Border.all(color: CG.border),
      ),
      child: Column(
        children: const [
          Icon(Icons.person_search_rounded,
              size: 42, color: CG.primary),
          SizedBox(height: 8),
          Text(
            'No patient linked yet',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: CG.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Ask your caregiver to share their Smaran ID.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: CG.textMuted),
          ),
        ],
      ),
    );
  }
}

class _GlanceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String sub;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _GlanceTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.sub,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(CG.rCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CG.rCard),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: fg, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: fg.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: fg,
                  height: 1.1,
                ),
              ),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10.5,
                  color: fg.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContributeCard extends StatelessWidget {
  final VoidCallback onAddMemory;
  final VoidCallback onAddRoutine;

  const _ContributeCard({
    required this.onAddMemory,
    required this.onAddRoutine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDCEFDC), Color(0xFFEBF5EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(CG.rCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.favorite_rounded,
                  color: CG.danger, size: 22),
              SizedBox(width: 8),
              Text(
                'Add to their story',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: CG.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Family memories make their games more meaningful.',
            style: TextStyle(
              fontSize: 12,
              color: CG.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _miniAction(
                  icon: Icons.add_a_photo_rounded,
                  label: 'Add Memory',
                  onTap: onAddMemory,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniAction(
                  icon: Icons.playlist_add_rounded,
                  label: 'Add Routine',
                  onTap: onAddRoutine,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: CG.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
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

class _FooterMessage extends StatelessWidget {
  const _FooterMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CG.rCard),
        border: Border.all(color: CG.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: CG.primaryPale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.volunteer_activism_rounded,
                color: CG.primary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your presence helps. Small contributions make a big difference.',
              style: TextStyle(
                fontSize: 12,
                color: CG.textPrimary,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}