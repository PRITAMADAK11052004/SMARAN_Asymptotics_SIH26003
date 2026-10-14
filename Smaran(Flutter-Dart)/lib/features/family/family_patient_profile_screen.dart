import 'package:flutter/material.dart';

import '../../core/auth/auth_store.dart';
import '../../core/domain/app_models.dart';
import '../../core/services/caregiver_analytics.dart';
import '../../core/theme/caregiver_theme.dart';
import '../../core/widgets/smaran_id_card.dart';
import '../../core/widgets/patient_avatar.dart';

class FamilyPatientProfileScreen extends StatelessWidget {
  final SmaranStore store;
  const FamilyPatientProfileScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final patients = AuthStore.instance.linkedPatients;
    if (patients.isEmpty) {
      return const Center(
        child: Text(
          'No patient linked.',
          style: TextStyle(color: CG.textMuted),
        ),
      );
    }
    final p = patients.first;
    final smrn = p.patientId ?? 'SMRN-XXXX-XXXX';
    final games = CaregiverAnalytics.gamesPlayedToday(store);
    final (medsDone, medsTotal) = CaregiverAnalytics.remindersToday(store);
    final mood = CaregiverAnalytics.moodLabel(store);
    final moodEmoji = CaregiverAnalytics.moodEmoji(store);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(CG.rCard),
              border: Border.all(color: CG.border),
            ),
            child: Row(
              children: [
                PatientAvatar(
                  user: p,
                  fallbackName: p.fullName,
                  size: 76,
                  circle: false,
                  borderColor: CG.primary,
                  onTap: p.facePhotoBase64 != null
                      ? () => showPatientPhotoViewer(
                          context,
                          base64Jpeg: p.facePhotoBase64!,
                          patientName: p.fullName,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: CG.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.relationship ?? 'Family',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: CG.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Center(child: SmaranIdCard(smrnId: smrn, size: 240)),
          const SizedBox(height: 16),

          _card(
            title: "Today's Summary",
            child: Row(
              children: [
                _miniStat('$games/5', 'Games', CG.gamesBg, CG.gamesFg),
                _miniStat(
                  '$medsDone/$medsTotal',
                  'Medicine',
                  CG.medicineBg,
                  CG.medicineFg,
                ),
                _miniStat(
                  '${store.hydrationToday()}/${store.hydrationTarget}',
                  'Hydration',
                  CG.hydrationBg,
                  CG.hydrationFg,
                ),
                _miniStat('$moodEmoji $mood', 'Mood', CG.moodBg, CG.moodFg),
              ],
            ),
          ),

          const SizedBox(height: 14),

          _card(
            title: 'About',
            child: Column(
              children: [
                _kv('Relationship', p.relationship ?? '—'),
                _kv('Language', 'English'),
                _kv('Linked since', _formatDate(p.createdAt)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day} ${_month(d.month)} ${d.year}';

  String _month(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

  Widget _miniStat(String value, String label, Color bg, Color fg) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: fg,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: CG.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            k,
            style: const TextStyle(fontSize: 12.5, color: CG.textMuted),
          ),
        ),
        Text(
          v,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: CG.textPrimary,
          ),
        ),
      ],
    ),
  );

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CG.rCard),
        border: Border.all(color: CG.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: CG.primary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
