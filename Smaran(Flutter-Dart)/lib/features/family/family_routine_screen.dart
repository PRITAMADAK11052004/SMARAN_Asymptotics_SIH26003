import 'package:flutter/material.dart';

import '../../core/domain/app_models.dart';
import '../../core/theme/caregiver_theme.dart';

class FamilyRoutineScreen extends StatefulWidget {
  final SmaranStore store;
  const FamilyRoutineScreen({super.key, required this.store});

  @override
  State<FamilyRoutineScreen> createState() => _FamilyRoutineScreenState();
}

class _FamilyRoutineScreenState extends State<FamilyRoutineScreen> {
  String _tab = 'Today';

  @override
  Widget build(BuildContext context) {
    final reminders = [...widget.store.reminders]
      ..sort((a, b) =>
          a.nextSystemDateTime.compareTo(b.nextSystemDateTime));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Routine',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: CG.primary)),
          const SizedBox(height: 4),
          const Text('Help keep the day on track',
              style: TextStyle(fontSize: 12, color: CG.textMuted)),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('Today'),
                const SizedBox(width: 8),
                _chip('Upcoming'),
                const SizedBox(width: 8),
                _chip('Completed'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (reminders.isEmpty)
            _empty()
          else
            ...reminders.map((r) => _RoutineTile(reminder: r)),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    final selected = _tab == label;
    return GestureDetector(
      onTap: () => setState(() => _tab = label),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CG.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: selected ? CG.primary : CG.border),
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

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CG.rCard),
        border: Border.all(color: CG.border),
      ),
      child: Column(
        children: const [
          Icon(Icons.checklist_rounded,
              size: 54, color: CG.primary),
          SizedBox(height: 12),
          Text('No routine set',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: CG.textPrimary)),
          SizedBox(height: 4),
          Text(
              'Ask your caregiver to add daily tasks and reminders.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: CG.textMuted)),
        ],
      ),
    );
  }
}

class _RoutineTile extends StatelessWidget {
  final AlarmReminder reminder;
  const _RoutineTile({required this.reminder});

  IconData get _icon => switch (reminder.alarmType) {
        AlarmType.medicine => Icons.medication_rounded,
        AlarmType.food => Icons.restaurant_rounded,
        AlarmType.memoryActivity => Icons.psychology_rounded,
        AlarmType.customTask => Icons.task_alt_rounded,
      };

  Color get _bg => switch (reminder.alarmType) {
        AlarmType.medicine => CG.medicineBg,
        AlarmType.food => CG.hydrationBg,
        AlarmType.memoryActivity => CG.gamesBg,
        AlarmType.customTask => CG.moodBg,
      };

  Color get _fg => switch (reminder.alarmType) {
        AlarmType.medicine => CG.medicineFg,
        AlarmType.food => CG.hydrationFg,
        AlarmType.memoryActivity => CG.gamesFg,
        AlarmType.customTask => CG.moodFg,
      };

  @override
  Widget build(BuildContext context) {
    final done = reminder.done;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CG.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _fg, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: done ? CG.textMuted : CG.textPrimary,
                    decoration: done
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reminder.time,
                  style: const TextStyle(
                      fontSize: 11.5, color: CG.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: done ? CG.primaryPale : CG.cardSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              done ? 'Completed' : 'Upcoming',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: done ? CG.primary : CG.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}