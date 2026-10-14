import 'package:flutter/material.dart';

import '../domain/app_models.dart';

/// Central mapping from reminder type + title → icon and background color.
///
/// Used by patient Reminders, Home Today's Plan, and Caregiver Reminders
/// so the same reminder always shows the same icon everywhere.
class ReminderIcons {
  ReminderIcons._();

  // ── Icon ───────────────────────────────────────────────
  static IconData iconFor(AlarmReminder r) {
    // Type-based first
    switch (r.alarmType) {
      case AlarmType.medicine:
        return Icons.medication_rounded;      // pill / tablet
      case AlarmType.food:
        return Icons.restaurant_rounded;      // spoon + plate
      case AlarmType.memoryActivity:
        return Icons.psychology_rounded;      // brain
      case AlarmType.customTask:
        break;
    }

    // Custom — infer from title
    final t = r.title.toLowerCase();
    if (t.contains('water') ||
        t.contains('drink') ||
        t.contains('hydrat') ||
        t.contains('পানি') ||
        t.contains('জল') ||
        t.contains('पानी')) {
      return Icons.local_drink_rounded;       // bottle
    }
    if (t.contains('music') ||
        t.contains('song') ||
        t.contains('radio') ||
        t.contains('গান') ||
        t.contains('संगीत')) {
      return Icons.music_note_rounded;
    }
    return Icons.task_alt_rounded;
  }

  // ── Background color ───────────────────────────────────
  static Color colorFor(AlarmReminder r) {
    switch (r.alarmType) {
      case AlarmType.medicine:
        return const Color(0xFFE5F0D8);       // soft green
      case AlarmType.food:
        return const Color(0xFFF5E6C7);       // cream
      case AlarmType.memoryActivity:
        return const Color(0xFFF6DCDD);       // pink
      case AlarmType.customTask:
        break;
    }

    final t = r.title.toLowerCase();
    if (t.contains('water') ||
        t.contains('drink') ||
        t.contains('hydrat') ||
        t.contains('পানি') ||
        t.contains('জল') ||
        t.contains('पानी')) {
      return const Color(0xFFDCECF2);         // light blue
    }
    if (t.contains('music') ||
        t.contains('song') ||
        t.contains('radio') ||
        t.contains('গান') ||
        t.contains('संगीत')) {
      return const Color(0xFFECE6F1);         // lavender
    }
    return const Color(0xFFE4F1D8);           // mint
  }

  // ── Category label ─────────────────────────────────────
  static String categoryLabel(AlarmReminder r) {
    switch (r.alarmType) {
      case AlarmType.medicine:
        return 'Medicine';
      case AlarmType.food:
        return 'Food';
      case AlarmType.memoryActivity:
        return 'Memory Activity';
      case AlarmType.customTask:
        break;
    }
    final t = r.title.toLowerCase();
    if (t.contains('water') ||
        t.contains('drink') ||
        t.contains('পানি') ||
        t.contains('जल')) {
      return 'Water';
    }
    if (t.contains('music') || t.contains('গান')) {
      return 'Music';
    }
    return 'Task';
  }
}