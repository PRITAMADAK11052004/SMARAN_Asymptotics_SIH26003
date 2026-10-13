import 'package:flutter_test/flutter_test.dart';
import 'package:smaran_flutter/core/domain/app_models.dart';
import 'package:smaran_flutter/core/games/difficulty_optimizer.dart';

void main() {
  test('difficulty reflects recent scores for a game', () {
    final now = DateTime(2026, 9, 11);

    GameSession s(int score, int daysAgo) => GameSession(
          gameId: 'memory_match',
          score: score,
          durationSec: 60,
          difficulty: 2,
          moves: 10,
          timestamp: now.subtract(Duration(days: daysAgo)),
        );

    // No history → level 1 (first-time default)
    expect(
      DifficultyOptimizer.instance.recommendedLevel('memory_match', const []),
      1,
    );

    // Average ~70 → level 3 ("Standard")
    expect(
      DifficultyOptimizer.instance.recommendedLevel(
        'memory_match',
        [s(70, 0), s(70, 1), s(70, 2)],
      ),
      3,
    );

    // Average 95 → level 5 ("Advanced")
    expect(
      DifficultyOptimizer.instance.recommendedLevel(
        'memory_match',
        [s(95, 0), s(95, 1), s(95, 2)],
      ),
      5,
    );
  });
}