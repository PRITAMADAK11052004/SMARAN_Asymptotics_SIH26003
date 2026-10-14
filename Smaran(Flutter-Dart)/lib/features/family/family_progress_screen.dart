import 'package:flutter/material.dart';

import '../../core/domain/app_models.dart';
import '../../core/services/caregiver_analytics.dart';
import '../../core/theme/caregiver_theme.dart';

class FamilyProgressScreen extends StatelessWidget {
  final SmaranStore store;
  const FamilyProgressScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final memory = _score(store, 'memory_match');
    final attention = _score(store, 'pattern_tap');
    final recognition = _score(store, 'word_picture');
    final routine = _score(store, 'sequence_recall');
    final gamesWeek = CaregiverAnalytics.gamesPlayedThisWeek(store);
    final streak = CaregiverAnalytics.dailyStreak(store);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress & Insights',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: CG.primary)),
          const SizedBox(height: 4),
          const Text('Weekly cognitive snapshot',
              style: TextStyle(fontSize: 12, color: CG.textMuted)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _metric('$gamesWeek', 'Games this week',
                    CG.gamesBg, CG.gamesFg,
                    Icons.sports_esports_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metric('$streak', 'Day streak', CG.moodBg,
                    CG.moodFg, Icons.local_fire_department_rounded),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Text('Cognitive Domains',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: CG.primary)),
          const SizedBox(height: 10),

          _bar('Memory', memory, CG.primaryMid,
              Icons.psychology_rounded),
          const SizedBox(height: 10),
          _bar('Attention', attention, CG.warning,
              Icons.center_focus_strong_rounded),
          const SizedBox(height: 10),
          _bar('Recognition', recognition, CG.info,
              Icons.visibility_rounded),
          const SizedBox(height: 10),
          _bar('Routine Recall', routine, CG.purple,
              Icons.repeat_rounded),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDDEBFA), Color(0xFFEBF5EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(CG.rCard),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: CG.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Keep engaging in daily activities and memory games. '
                    'Small, consistent practice makes a big difference.',
                    style: TextStyle(
                      fontSize: 12,
                      color: CG.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _score(SmaranStore store, String gameId) {
    final s = store.sessionsFor(gameId).take(5).toList();
    if (s.isEmpty) return 0;
    final avg = s.map((e) => e.score).reduce((a, b) => a + b) / s.length;
    return avg.round().clamp(0, 100);
  }

  Widget _metric(
      String v, String label, Color bg, Color fg, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(height: 8),
          Text(v,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: fg)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: fg.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  Widget _bar(String label, int percent, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CG.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: CG.textPrimary)),
                    const Spacer(),
                    Text('$percent%',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: color)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 7,
                    backgroundColor:
                        color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}