import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth/auth_store.dart';
import '../../core/domain/app_models.dart';
import '../../core/services/caregiver_analytics.dart';
import '../../core/theme/caregiver_theme.dart';

class CaregiverHomeScreen extends StatefulWidget {
  final SmaranStore store;
  final void Function(int) onNavigate;
  const CaregiverHomeScreen({
    super.key,
    required this.store,
    required this.onNavigate,
  });

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> {
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

  void _toast(String msg, {bool danger = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: danger ? CG.danger : CG.primary,
      ),
    );
  }

  Future<void> _callPatient() async {
    final patients = AuthStore.instance.linkedPatients;
    if (patients.isEmpty) return;
    final phone = patients.first.phone.trim();
    if (phone.isEmpty) {
      _toast('No phone number on file for this patient.',
          danger: true);
      return;
    }
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _toast('Cannot open the dialer on this device.', danger: true);
      }
    } catch (_) {
      _toast('Could not start the call.', danger: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final caregiver = AuthStore.instance.currentUser;
    final patients = AuthStore.instance.linkedPatients;
    final firstPatient = patients.isNotEmpty ? patients.first : null;

    final gamesToday = CaregiverAnalytics.gamesPlayedToday(store);
    final mood = CaregiverAnalytics.moodLabel(store);
    final moodEmoji = CaregiverAnalytics.moodEmoji(store);
    final (medsDone, medsTotal) =
        CaregiverAnalytics.remindersToday(store);
    final (missedMeds, _) =
        CaregiverAnalytics.missedMedicinesToday(store);

    final hydrationDone = store.hydrationToday();
    final hydrationTotal = store.hydrationTarget;

    final firstName = caregiver?.fullName.split(' ').first ?? 'Caregiver';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      "Here's how your patient is doing today.",
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

          if (firstPatient != null)
            _PatientSelector(name: firstPatient.fullName),

          const SizedBox(height: 12),

          if (firstPatient != null)
            _PatientOverviewCard(patient: firstPatient),

          const SizedBox(height: 20),

          const _SectionLabel('TODAY'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.sports_esports_rounded,
                  value: '$gamesToday / 5',
                  sub: 'completed',
                  label: 'Games',
                  bg: CG.gamesBg,
                  fg: CG.gamesFg,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.medication_rounded,
                  value: '$medsDone / $medsTotal',
                  sub: 'taken',
                  label: 'Medicine',
                  bg: CG.medicineBg,
                  fg: CG.medicineFg,
                  highlight: missedMeds > 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.local_drink_rounded,
                  value: '$hydrationDone / $hydrationTotal',
                  sub: 'glasses',
                  label: 'Hydration',
                  bg: CG.hydrationBg,
                  fg: CG.hydrationFg,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  emoji: moodEmoji,
                  value: mood,
                  sub: '',
                  label: 'Mood',
                  bg: CG.moodBg,
                  fg: CG.moodFg,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),
          const _SectionLabel('QUICK ACTIONS'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.phone_rounded,
                  label:
                      'Call ${firstPatient?.fullName.split(' ').first ?? 'Patient'}',
                  onTap: _callPatient,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.notifications_active_rounded,
                  label: 'Check Alerts',
                  onTap: () => widget.onNavigate(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.photo_library_rounded,
                  label: 'Memory Bank',
                  onTap: () => widget.onNavigate(5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Generate Report',
                  onTap: () => widget.onNavigate(6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),
          _MotivationBanner(),
        ],
      ),
    );
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

class _PatientSelector extends StatelessWidget {
  final String name;
  const _PatientSelector({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CG.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline_rounded,
              size: 20, color: CG.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: CG.textPrimary,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: CG.primaryPale,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: CG.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: CG.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded,
              color: CG.textMuted, size: 22),
        ],
      ),
    );
  }
}

class _PatientOverviewCard extends StatelessWidget {
  final dynamic patient;
  const _PatientOverviewCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final name = patient.fullName as String;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';


    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CG.rCard),
        border: Border.all(color: CG.border),
        boxShadow: CG.cardShadow,
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: CG.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: CG.primary,
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: CG.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: CG.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: CG.primaryPale,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_rounded,
                              size: 12, color: CG.success),
                          SizedBox(width: 4),
                          Text(
                            'Stable',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: CG.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Last synced: 2 min ago',
                      style: TextStyle(
                          fontSize: 10.5, color: CG.textFaint),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String value;
  final String sub;
  final String label;
  final Color bg;
  final Color fg;
  final bool highlight;

  const _StatTile({
    this.icon,
    this.emoji,
    required this.value,
    required this.sub,
    required this.label,
    required this.bg,
    required this.fg,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(CG.rCard),
        border: highlight
            ? Border.all(color: CG.danger, width: 1.5)
            : null,
      ),
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
            child: emoji != null
                ? Text(emoji!, style: const TextStyle(fontSize: 18))
                : Icon(icon, color: fg, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: fg,
              height: 1.1,
            ),
          ),
          if (sub.isNotEmpty)
            Text(
              sub,
              style: TextStyle(
                fontSize: 11,
                color: fg.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: fg.withValues(alpha: 0.85),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(CG.rButton),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CG.rButton),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CG.rButton),
            border: Border.all(color: CG.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: CG.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
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

class _MotivationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDCEFDC), Color(0xFFEBF5EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(CG.rCard),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'A healthier mind',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: CG.primary,
                  ),
                ),
                Text(
                  'builds a brighter tomorrow',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: CG.primary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Keep up the daily routine — it makes a real difference.',
                  style:
                      TextStyle(fontSize: 11.5, color: CG.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.favorite_rounded,
              color: CG.danger, size: 34),
        ],
      ),
    );
  }
}