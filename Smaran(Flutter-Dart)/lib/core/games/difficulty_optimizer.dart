import '../domain/app_models.dart';

/// Central adaptive difficulty engine.
///
/// Every game asks: "what level should I run at?"
/// Level is derived from the last 5 sessions for that specific game.
///
/// Levels:
///   1 = Easy         (best for first-time patients)
///   2 = Gentle
///   3 = Standard
///   4 = Challenging
///   5 = Advanced
class DifficultyOptimizer {
  DifficultyOptimizer._();
  static final DifficultyOptimizer instance = DifficultyOptimizer._();

  static const int minLevel = 1;
  static const int maxLevel = 5;
  static const int _windowSize = 5;

  /// Recommended level (1..5) for [gameId] based on recent sessions.
  /// Returns 1 if there is no data yet.
  int recommendedLevel(String gameId, List<GameSession> allSessions) {
    final recent = _recentFor(gameId, allSessions);
    if (recent.isEmpty) return 1;

    final avgScore = recent
            .map((s) => s.score)
            .reduce((a, b) => a + b) /
        recent.length;

    if (avgScore >= 90) return 5;
    if (avgScore >= 80) return 4;
    if (avgScore >= 65) return 3;
    if (avgScore >= 50) return 2;
    return 1;
  }

  /// Human-readable label for a level.
  String levelLabel(int level) => switch (level) {
        1 => 'Easy',
        2 => 'Gentle',
        3 => 'Standard',
        4 => 'Challenging',
        5 => 'Advanced',
        _ => 'Easy',
      };

  /// Short theme color for a level.
  int levelColorValue(int level) => switch (level) {
        1 => 0xFFE5F0D8, // soft green
        2 => 0xFFF5E6C7, // warm cream
        3 => 0xFFDCECF2, // light blue
        4 => 0xFFF6DCDD, // soft pink
        5 => 0xFFECE6F1, // lavender
        _ => 0xFFE5F0D8,
      };

  /// Trend indicator: 'up', 'down', 'flat', or 'none'.
  String trendFor(String gameId, List<GameSession> allSessions) {
    final recent = _recentFor(gameId, allSessions);
    if (recent.length < 4) return 'none';

    final sorted = [...recent]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final half = sorted.length ~/ 2;
    final firstHalf = sorted.take(half);
    final secondHalf = sorted.skip(half);

    final avgFirst = firstHalf.map((s) => s.score).reduce((a, b) => a + b) /
        firstHalf.length;
    final avgSecond =
        secondHalf.map((s) => s.score).reduce((a, b) => a + b) /
            secondHalf.length;

    final delta = avgSecond - avgFirst;
    if (delta > 5) return 'up';
    if (delta < -5) return 'down';
    return 'flat';
  }

  /// True if the last session was significantly better than the prior ones,
  /// meaning the user earned a level-up.
  bool didJustLevelUp(String gameId, List<GameSession> allSessions) {
    final recent = _recentFor(gameId, allSessions);
    if (recent.length < 3) return false;

    final latest = recent.first.score;
    final priorAvg = recent
            .skip(1)
            .take(4)
            .map((s) => s.score)
            .reduce((a, b) => a + b) /
        recent.skip(1).take(4).length;

    return latest >= 85 && (latest - priorAvg) >= 10;
  }

  /// Number of distinct games the patient has completed today.
  int completedToday(List<GameSession> allSessions) {
    final today = DateTime.now();
    final ids = <String>{};
    for (final s in allSessions) {
      if (s.timestamp.year == today.year &&
          s.timestamp.month == today.month &&
          s.timestamp.day == today.day) {
        ids.add(s.gameId);
      }
    }
    return ids.length;
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  List<GameSession> _recentFor(String gameId, List<GameSession> all) {
    final list = all.where((s) => s.gameId == gameId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.take(_windowSize).toList();
  }
}