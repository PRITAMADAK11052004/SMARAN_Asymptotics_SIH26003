import 'package:flutter/material.dart';

import '../../core/auth/auth_store.dart';
import '../../core/domain/app_models.dart';
import '../../core/services/caregiver_analytics.dart';
import '../../core/theme/caregiver_theme.dart';
import '../../core/widgets/smaran_id_card.dart';
import '../../core/widgets/patient_avatar.dart';

class CaregiverPatientProfileScreen extends StatefulWidget {
  final SmaranStore store;
  const CaregiverPatientProfileScreen({super.key, required this.store});

  @override
  State<CaregiverPatientProfileScreen> createState() =>
      _CaregiverPatientProfileScreenState();
}

class _CaregiverPatientProfileScreenState
    extends State<CaregiverPatientProfileScreen> {
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
    final store = widget.store;
    final games = CaregiverAnalytics.gamesPlayedToday(store);
    final (medsDone, medsTotal) = CaregiverAnalytics.remindersToday(store);
    final mood = CaregiverAnalytics.moodLabel(store);
    final moodEmoji = CaregiverAnalytics.moodEmoji(store);

    final smrn = p.patientId ?? 'SMRN-XXXX-XXXX';

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
                      const Text(
                        'Linked patient',
                        style: TextStyle(fontSize: 12.5, color: CG.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: CG.primaryPale,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Stable',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: CG.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Smaran ID / QR toggle card
          Center(child: SmaranIdCard(smrnId: smrn, size: 240)),

          const SizedBox(height: 16),

          _Card(
            title: "Today's Summary",
            subtitle: 'Today',
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

          _Card(
            title: 'Recent Activity',
            child: Column(
              children: [
                _activityRow(
                  Icons.sports_esports_rounded,
                  'Memory Match',
                  'Completed • 82%',
                  '10:34 AM',
                ),
                _activityRow(
                  Icons.medication_rounded,
                  'Morning Medicine',
                  'Confirmed',
                  '09:45 AM',
                ),
                _activityRow(
                  Icons.radio_rounded,
                  'Radio',
                  '18 min',
                  '09:20 AM',
                ),
                _activityRow(
                  Icons.photo_library_rounded,
                  'Memory Garden',
                  'Viewed 3 memories',
                  '08:55 AM',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                fontSize: 13,
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

  Widget _activityRow(IconData icon, String title, String detail, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: CG.primaryPale,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: CG.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: CG.textPrimary,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 11.5, color: CG.textMuted),
                ),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 11, color: CG.textFaint)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _Card({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
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
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 11, color: CG.textMuted),
            ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
