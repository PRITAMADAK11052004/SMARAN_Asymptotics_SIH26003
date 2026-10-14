import 'package:flutter/material.dart';

import '../../core/domain/app_models.dart';
import '../../core/theme/caregiver_theme.dart';

class CaregiverProgressScreen extends StatelessWidget {
  final SmaranStore store;
  const CaregiverProgressScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final memory = _domainScore(store, 'memory_match');
    final attention = _domainScore(store, 'pattern_tap');
    final recognition = _domainScore(store, 'word_picture');
    final routine = _domainScore(store, 'sequence_recall');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cognitive Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: CG.primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Last 7 Days',
              style: TextStyle(fontSize: 12, color: CG.textMuted)),
          const SizedBox(height: 16),

          _DomainBar(
            icon: Icons.psychology_rounded,
            label: 'Memory',
            percent: memory,
            color: CG.primaryMid,
          ),
          const SizedBox(height: 12),
          _DomainBar(
            icon: Icons.center_focus_strong_rounded,
            label: 'Attention',
            percent: attention,
            color: CG.warning,
          ),
          const SizedBox(height: 12),
          _DomainBar(
            icon: Icons.visibility_rounded,
            label: 'Recognition',
            percent: recognition,
            color: CG.info,
          ),
          const SizedBox(height: 12),
          _DomainBar(
            icon: Icons.repeat_rounded,
            label: 'Routine Recall',
            percent: routine,
            color: CG.purple,
          ),

          const SizedBox(height: 20),

          // Progress trend chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(CG.rCard),
              border: Border.all(color: CG.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Progress Trend (Last 7 Days)',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: CG.primary)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: CustomPaint(
                    painter: _TrendPainter(store: store),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // AI Insight
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Insight',
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: CG.primary)),
                      SizedBox(height: 4),
                      Text(
                        'Patient is performing well in memory games. '
                        'However, attention response time has increased '
                        'in the last 4 sessions.',
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: CG.textPrimary),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'View Suggestions →',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: CG.info),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _domainScore(SmaranStore store, String gameId) {
    final sessions = store.sessionsFor(gameId).take(5).toList();
    if (sessions.isEmpty) return 0;
    final avg = sessions.map((s) => s.score).reduce((a, b) => a + b) /
        sessions.length;
    return avg.round().clamp(0, 100);
  }
}

class _DomainBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final int percent;
  final Color color;

  const _DomainBar({
    required this.icon,
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
                    backgroundColor: color.withValues(alpha: 0.15),
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

class _TrendPainter extends CustomPainter {
  final SmaranStore store;
  _TrendPainter({required this.store});

  @override
  void paint(Canvas canvas, Size size) {
    final series = _series(store);

    final gridPaint = Paint()
      ..color = CG.border
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (series.isEmpty) return;

    final paint = Paint()
      ..color = CG.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final stepX = size.width / (series.length - 1).clamp(1, 100);
    final points = <Offset>[];
    for (int i = 0; i < series.length; i++) {
      final x = i * stepX;
      final v = (series[i] / 100).clamp(0.0, 1.0);
      final y = size.height - v * size.height;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);

    for (final p in points) {
      canvas.drawCircle(p, 5, Paint()..color = CG.primary);
      canvas.drawCircle(p, 2.5, Paint()..color = Colors.white);
    }
  }

  List<double> _series(SmaranStore store) {
    final now = DateTime.now();
    final buckets = <int, List<int>>{};
    for (final s in store.gameSessions) {
      final days = now.difference(s.timestamp).inDays;
      if (days < 0 || days > 6) continue;
      buckets.putIfAbsent(6 - days, () => []).add(s.score);
    }
    return List.generate(7, (i) {
      final list = buckets[i];
      if (list == null || list.isEmpty) return 0.0;
      return list.reduce((a, b) => a + b) / list.length;
    });
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.store != store;
}