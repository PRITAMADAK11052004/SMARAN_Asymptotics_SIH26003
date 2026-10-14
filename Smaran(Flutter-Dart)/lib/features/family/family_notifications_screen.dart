import 'package:flutter/material.dart';

import '../../core/domain/app_models.dart';
import '../../core/services/caregiver_analytics.dart';
import '../../core/theme/caregiver_theme.dart';

class FamilyNotificationsScreen extends StatefulWidget {
  final SmaranStore store;
  const FamilyNotificationsScreen({super.key, required this.store});

  @override
  State<FamilyNotificationsScreen> createState() =>
      _FamilyNotificationsScreenState();
}

class _FamilyNotificationsScreenState
    extends State<FamilyNotificationsScreen> {
  String _tab = 'All';

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final (medsDone, medsTotal) =
        CaregiverAnalytics.remindersToday(store);
    final mood = CaregiverAnalytics.moodLabel(store);

    final items = <_Notif>[
      _Notif(
        title: 'Medicine reminder sent',
        detail: '$medsDone of $medsTotal confirmed today',
        severity: 'High',
        icon: Icons.medication_rounded,
        time: '12:00 PM',
      ),
      _Notif(
        title: 'Hydration update',
        detail:
            '${store.hydrationToday()}/${store.hydrationTarget} glasses today',
        severity: 'High',
        icon: Icons.local_drink_rounded,
        time: '3:00 PM',
      ),
      _Notif(
        title: 'New memory added',
        detail: 'A family photo was added recently.',
        severity: 'Normal',
        icon: Icons.photo_library_rounded,
        time: 'Today',
      ),
      _Notif(
        title: 'Mood update',
        detail: 'Current mood: $mood',
        severity: 'Normal',
        icon: Icons.favorite_rounded,
        time: 'Today',
      ),
    ];

    final visible = _tab == 'All'
        ? items
        : _tab == 'Reminders'
            ? items.take(2).toList()
            : <_Notif>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notifications',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: CG.primary)),
          const SizedBox(height: 4),
          const Text('Recent updates from your patient',
              style: TextStyle(fontSize: 12, color: CG.textMuted)),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('All'),
                const SizedBox(width: 8),
                _chip('Reminders'),
                const SizedBox(width: 8),
                _chip('Updates'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(CG.rCard),
                border: Border.all(color: CG.border),
              ),
              child: const Center(
                child: Text('No notifications here.',
                    style: TextStyle(color: CG.textMuted)),
              ),
            )
          else
            ...visible.map((n) => _NotifTile(n: n)),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    final selected = _tab == label;
    return GestureDetector(
      onTap: () => setState(() => _tab = label),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CG.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: selected ? CG.primary : CG.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : CG.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _Notif {
  final String title;
  final String detail;
  final String severity;
  final IconData icon;
  final String time;
  _Notif({
    required this.title,
    required this.detail,
    required this.severity,
    required this.icon,
    required this.time,
  });
}

class _NotifTile extends StatelessWidget {
  final _Notif n;
  const _NotifTile({required this.n});

  Color get _color => n.severity == 'High' ? CG.danger : CG.info;
  Color get _bg =>
      n.severity == 'High' ? const Color(0xFFFADCDC) : const Color(0xFFDDEBFA);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(n.icon, color: _color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: _color)),
                const SizedBox(height: 2),
                Text(n.detail,
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: CG.textPrimary,
                        height: 1.4)),
                const SizedBox(height: 4),
                Text(n.time,
                    style: const TextStyle(
                        fontSize: 10, color: CG.textFaint)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(n.severity,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _color)),
          ),
        ],
      ),
    );
  }
}