/// Single source of truth for game scoring formulas.
/// Keep screens out of the math business.
class GameScoring {
  /// Memory Match: perfect play is 1 move per pair (a "move" is
  /// counted only when the second card of a pair is flipped).
  /// Every extra move costs 3 points.
  static int memoryMatch({required int moves, required int pairs}) {
    final excess = (moves - pairs).clamp(0, 100);
    return (100 - excess * 3).clamp(0, 100);
  }

  /// Generic accuracy score: correct / total as a percentage.
  static int accuracy({required int correct, required int total}) {
    if (total <= 0) return 0;
    return ((correct / total) * 100).round().clamp(0, 100);
  }
}