import 'package:flutter/material.dart';

import '../../core/domain/app_models.dart';
import '../../core/services/caregiver_analytics.dart';
import '../../core/theme/caregiver_theme.dart';

class CaregiverAlertsScreen extends StatefulWidget {
  final SmaranStore store;
  const CaregiverAlertsScreen({super.key, required this.store});

  @override
  State<CaregiverAlertsScreen> createState() =>
      _CaregiverAlertsScreenState();
}

class _CaregiverAlertsScreenState extends State<CaregiverAlertsScreen> {
  _Sev? _filter;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final (missed, _) = CaregiverAnalytics.missedMedicinesToday(store);
    final games = CaregiverAnalytics.gamesPlayedToday(store);
    final mood = CaregiverAnalytics.moodLabel(store);

    final alerts = <_Alert>[
      if (missed > 0)
        _Alert(
          severity: _Sev.urgent,
          title: 'Missed Medicine',
          detail: 'Today, $missed dose(s) not confirmed.',
          time: 'Today',
          icon: Icons.medication_rounded,
        ),
      _Alert(
        severity: _Sev.attention,
        title: 'Hydration Below Target',
        detail:
            'Only ${store.hydrationToday()}/${store.hydrationTarget} glasses completed today.',
        time: 'Today',
        icon: Icons.local_drink_rounded,
      ),
      if (games < 5)
        _Alert(
          severity: _Sev.observation,
          title: 'Game Completion Pending',
          detail: '$games of 5 games completed today.',
          time: 'Today',
          icon: Icons.sports_esports_rounded,
        ),
      _Alert(
        severity: _Sev.info,
        title: 'Memory Performance',
        detail: 'Latest session score is trending well.',
        time: 'Today',
        icon: Icons.trending_up_rounded,
      ),
      _Alert(
        severity: _Sev.info,
        title: 'Routine Reminder',
        detail: 'Afternoon rest not yet completed.',
        time: 'Today',
        icon: Icons.alarm_rounded,
      ),
      _Alert(
        severity: _Sev.info,
        title: 'Mood Today',
        detail: 'Current mood: $mood',
        time: 'Today',
        icon: Icons.favorite_rounded,
      ),
    ];

    final visible = alerts
        .where((a) => _filter == null || a.severity == _filter)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alerts & Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: CG.primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Important activity from your patient',
              style: TextStyle(fontSize: 12, color: CG.textMuted)),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('All', null),
                const SizedBox(width: 8),
                _chip('Urgent', _Sev.urgent),
                const SizedBox(width: 8),
                _chip('Attention', _Sev.attention),
                const SizedBox(width: 8),
                _chip('Info', _Sev.info),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (visible.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(CG.rCard),
                border: Border.all(color: CG.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: CG.success, size: 48),
                  SizedBox(height: 10),
                  Text('No alerts in this category',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: CG.textPrimary)),
                ],
              ),
            )
          else
            ...visible.map((a) => _AlertCard(alert: a)),
        ],
      ),
    );
  }

  Widget _chip(String label, _Sev? sev) {
    final selected = _filter == sev;
    return GestureDetector(
      onTap: () => setState(() => _filter = sev),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CG.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? CG.primary : CG.border),
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

enum _Sev { urgent, attention, observation, info }

class _Alert {
  final _Sev severity;
  final String title;
  final String detail;
  final String time;
  final IconData icon;
  const _Alert({
    required this.severity,
    required this.title,
    required this.detail,
    required this.time,
    required this.icon,
  });
}

class _AlertCard extends StatelessWidget {
  final _Alert alert;
  const _AlertCard({required this.alert});

  Color get _color => switch (alert.severity) {
        _Sev.urgent => CG.danger,
        _Sev.attention => CG.warning,
        _Sev.observation => CG.info,
        _Sev.info => CG.success,
      };

  Color get _bg => switch (alert.severity) {
        _Sev.urgent => const Color(0xFFFADCDC),
        _Sev.attention => const Color(0xFFFFF1D6),
        _Sev.observation => const Color(0xFFDDEBFA),
        _Sev.info => CG.primaryPale,
      };

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
            child: Icon(alert.icon, color: _color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: _color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.detail,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: CG.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.time,
                  style: const TextStyle(
                      fontSize: 10, color: CG.textFaint),
                ),
              ],
            ),
          ),
          Text(
            'View',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}