import '../domain/app_models.dart';

/// Pure computation of caregiver-facing metrics from [SmaranStore].
///
/// No state — just static helpers. All methods are safe to call with
/// an empty store (return 0 / empty list / neutral values).
class CaregiverAnalytics {
  CaregiverAnalytics._();

  // ═══════════════════════════════════════════════════════════
  // GAMES
  // ═══════════════════════════════════════════════════════════

  /// Number of distinct games played today (max 5).
  static int gamesPlayedToday(SmaranStore store) {
    final today = DateTime.now();
    final ids = <String>{};
    for (final s in store.gameSessions) {
      if (_sameDay(s.timestamp, today)) ids.add(s.gameId);
    }
    return ids.length;
  }

  /// Total games played this week (sum across all sessions).
  static int gamesPlayedThisWeek(SmaranStore store) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    return store.gameSessions
        .where((s) => s.timestamp.isAfter(cutoff))
        .length;
  }

  /// Distinct games played per day over the last 7 days.
  /// Index 0 = 6 days ago, index 6 = today.
  static List<int> weeklyGameCounts(SmaranStore store) {
    final now = DateTime.now();
    final result = <int>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final ids = <String>{};
      for (final s in store.gameSessions) {
        if (_sameDay(s.timestamp, day)) ids.add(s.gameId);
      }
      result.add(ids.length);
    }
    return result;
  }

  /// True if all 7 days of the current week have zero engagement.
  static bool isWeekCompletelyEmpty(SmaranStore store) {
    return weeklyGameCounts(store).every((c) => c == 0);
  }

  // ═══════════════════════════════════════════════════════════
  // COGNITIVE SCORE
  // ═══════════════════════════════════════════════════════════

  /// Average score per day over the last 7 days.
  /// Index 0 = 6 days ago, index 6 = today.
  static List<double> weeklyScoreTrend(SmaranStore store) {
    final now = DateTime.now();
    final result = <double>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final scores = <int>[];
      for (final s in store.gameSessions) {
        if (_sameDay(s.timestamp, day)) scores.add(s.score);
      }
      result.add(
        scores.isEmpty
            ? 0
            : scores.reduce((a, b) => a + b) / scores.length,
      );
    }
    return result;
  }

  /// Average of the last 5 sessions (or fewer if not enough data).
  static int averageRecentScore(SmaranStore store) {
    if (store.gameSessions.isEmpty) return 0;
    final sorted = [...store.gameSessions]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recent = sorted.take(5);
    final sum = recent.fold<int>(0, (acc, s) => acc + s.score);
    return (sum / recent.length).round();
  }

  /// Whether the score is trending up, down, or flat over the last 5 sessions.
  /// Returns 'up', 'down', 'flat', or 'none'.
  static String scoreTrendDirection(SmaranStore store) {
    if (store.gameSessions.length < 4) return 'none';
    final sorted = [...store.gameSessions]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final recent = sorted.reversed.take(5).toList().reversed.toList();
    final firstHalf = recent.take(recent.length ~/ 2);
    final secondHalf = recent.skip(recent.length ~/ 2);
    final avgFirst = firstHalf.isEmpty
        ? 0
        : firstHalf.fold<int>(0, (a, s) => a + s.score) / firstHalf.length;
    final avgSecond = secondHalf.isEmpty
        ? 0
        : secondHalf.fold<int>(0, (a, s) => a + s.score) / secondHalf.length;
    final delta = avgSecond - avgFirst;
    if (delta > 5) return 'up';
    if (delta < -5) return 'down';
    return 'flat';
  }

  // ═══════════════════════════════════════════════════════════
  // MOOD (derived from recent game performance)
  // ═══════════════════════════════════════════════════════════

  /// Emoji mood based on recent game performance.
  /// - 😊 Happy       (avg ≥ 80)
  /// - 😌 Calm        (avg ≥ 60)
  /// - 😐 Neutral     (avg ≥ 40)
  /// - 😔 Low         (avg < 40)
  /// - 😐 No data
  static String moodEmoji(SmaranStore store) {
    if (store.gameSessions.isEmpty) return '😐';
    final avg = averageRecentScore(store);
    if (avg >= 80) return '😊';
    if (avg >= 60) return '😌';
    if (avg >= 40) return '😐';
    return '😔';
  }

  /// Human-readable label for the mood.
  static String moodLabel(SmaranStore store) {
    if (store.gameSessions.isEmpty) return 'No data';
    final avg = averageRecentScore(store);
    if (avg >= 80) return 'Happy';
    if (avg >= 60) return 'Calm';
    if (avg >= 40) return 'Neutral';
    return 'Low';
  }

  /// Emoji per day over the last 7 days (oldest → newest).
  /// Returns `''` for days with no sessions.
  static List<String> weeklyMoodEmojis(SmaranStore store) {
    final now = DateTime.now();
    final result = <String>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final scores = <int>[];
      for (final s in store.gameSessions) {
        if (_sameDay(s.timestamp, day)) scores.add(s.score);
      }
      if (scores.isEmpty) {
        result.add('');
      } else {
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        if (avg >= 80) {
          result.add('😊');
        } else if (avg >= 60) {
          result.add('😌');
        } else if (avg >= 40) {
          result.add('😐');
        } else {
          result.add('😔');
        }
      }
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════
  // STREAK
  // ═══════════════════════════════════════════════════════════

  /// Consecutive days (ending today) with at least one game session.
  /// If today has no session, counts backward from yesterday.
  static int dailyStreak(SmaranStore store) {
    if (store.gameSessions.isEmpty) return 0;
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final day = now.subtract(Duration(days: i));
      final played =
          store.gameSessions.any((s) => _sameDay(s.timestamp, day));
      if (played) {
        streak++;
      } else if (i > 0) {
        break;
      }
      // If today has no play, allow the loop to continue to yesterday.
    }
    return streak;
  }

  // ═══════════════════════════════════════════════════════════
  // REMINDERS
  // ═══════════════════════════════════════════════════════════

  /// (completed, total) reminders today.
  /// Currently counts all reminders in the store (done + pending).
  static (int done, int total) remindersToday(SmaranStore store) {
    int done = 0;
    for (final r in store.reminders) {
      if (r.done) done++;
    }
    return (done, store.reminders.length);
  }

  /// Compliance percentage (0–100) across all saved reminders.
  static int reminderCompliancePercent(SmaranStore store) {
    if (store.reminders.isEmpty) return 0;
    final done = store.reminders.where((r) => r.done).length;
    return ((done / store.reminders.length) * 100).round();
  }

  // ═══════════════════════════════════════════════════════════
  // MISSED MEDICINES
  // ═══════════════════════════════════════════════════════════

  /// (missed, total) medicine reminders due today.
  ///
  /// A medicine is "missed" if:
  ///   - it is a medicine reminder
  ///   - it is active
  ///   - its next scheduled time is in the past
  ///   - it has not been marked done
  ///
  /// This powers the ALERT card on the caregiver dashboard.
  static (int missed, int total) missedMedicinesToday(SmaranStore store) {
    final now = DateTime.now();
    int missed = 0;
    int total = 0;
    for (final r in store.reminders) {
      if (r.alarmType != AlarmType.medicine) continue;
      if (!r.isActive) continue;
      total++;
      final target = r.nextSystemDateTime;
      if (target.isBefore(now) && !r.done) {
        missed++;
      }
    }
    return (missed, total);
  }

  // ═══════════════════════════════════════════════════════════
  // LAST ACTIVITY
  // ═══════════════════════════════════════════════════════════

  /// Time of the most recent game session, or null if no data.
  static DateTime? lastActivityTime(SmaranStore store) {
    if (store.gameSessions.isEmpty) return null;
    final sorted = [...store.gameSessions]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.first.timestamp;
  }

  /// Human label like "Active now", "15m ago", "3h ago", "2d ago".
  static String activityRecencyLabel(SmaranStore store) {
    final t = lastActivityTime(store);
    if (t == null) return 'No activity';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 5) return 'Active now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// True if the patient has been active in the last 5 minutes.
  static bool isActiveNow(SmaranStore store) {
    final t = lastActivityTime(store);
    if (t == null) return false;
    return DateTime.now().difference(t).inMinutes < 5;
  }

  // ═══════════════════════════════════════════════════════════
  // ALERTS
  // ═══════════════════════════════════════════════════════════

  /// Human-readable alerts for the caregiver to act on.
  /// Ordered by priority, max 5.
  static List<CaregiverAlert> recentAlerts(SmaranStore store) {
    final alerts = <CaregiverAlert>[];
    final now = DateTime.now();

    // Missed reminders
    for (final r in store.reminders) {
      if (!r.done && r.isActive) {
        final target = r.nextSystemDateTime;
        if (target.isBefore(now.subtract(const Duration(hours: 1)))) {
          alerts.add(CaregiverAlert(
            level: AlertLevel.warning,
            icon: '💊',
            title: 'Missed reminder',
            detail: '${r.title} at ${r.time}',
          ));
        }
      }
    }

    // No activity today
    if (gamesPlayedToday(store) == 0 && store.gameSessions.isNotEmpty) {
      alerts.add(const CaregiverAlert(
        level: AlertLevel.info,
        icon: '🎮',
        title: 'No games today',
        detail: 'Patient has not played any games today.',
      ));
    }

    // Score trending down
    if (scoreTrendDirection(store) == 'down') {
      alerts.add(const CaregiverAlert(
        level: AlertLevel.warning,
        icon: '📉',
        title: 'Cognitive score trending down',
        detail: 'Recent game scores are lower than earlier.',
      ));
    }

    // Positive reinforcement
    if (dailyStreak(store) >= 3) {
      alerts.add(CaregiverAlert(
        level: AlertLevel.success,
        icon: '🔥',
        title: '${dailyStreak(store)}-day streak!',
        detail: 'Patient has played games every day this week.',
      ));
    }

    return alerts.take(5).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Short day label for chart x-axes: "Mon", "Tue", ...
  static String dayLabel(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}

// =============================================================================
// SUPPORT TYPES
// =============================================================================

enum AlertLevel { info, warning, success }

class CaregiverAlert {
  final AlertLevel level;
  final String icon;
  final String title;
  final String detail;

  const CaregiverAlert({
    required this.level,
    required this.icon,
    required this.title,
    required this.detail,
  });
}