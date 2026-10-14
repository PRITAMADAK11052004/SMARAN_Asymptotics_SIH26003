import 'package:flutter/material.dart';

import '../../core/auth/auth_store.dart';
import '../../core/domain/app_models.dart';
import '../../core/localization/app_languages.dart';
import '../../core/services/alarm_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/reminder_icons.dart';
import '../talk/talking_screen.dart';

class RemindersScreen extends StatefulWidget {
  final SmaranStore store;
  const RemindersScreen({super.key, required this.store});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.store.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _addViaVoice() async {
    final result = await Navigator.push<AlarmReminder>(
      context,
      MaterialPageRoute(builder: (_) => const TalkingScreen()),
    );
    if (result == null) return;

    try {
      await AlarmService.requestPermissions();
      widget.store.reminders.add(result);
      await AlarmService.schedule(result);
      await widget.store.save();
      if (mounted) setState(() {});
      _message('Reminder added: "${result.title}"');
    } catch (_) {
      _message('Could not schedule the alarm.', error: true);
    }
  }

  Future<void> _editReminder(AlarmReminder reminder) async {
    final updated = await showDialog<AlarmReminder>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReminderEditorDialog(initial: reminder),
    );
    if (updated == null) return;

    try {
      await AlarmService.cancel(reminder.id);
      final idx =
          widget.store.reminders.indexWhere((r) => r.id == reminder.id);
      if (idx >= 0) widget.store.reminders[idx] = updated;
      await AlarmService.schedule(updated);
      await widget.store.save();
      if (mounted) setState(() {});
      _message('Reminder updated.');
    } catch (_) {
      _message('Could not update.', error: true);
    }
  }

  Future<void> _toggle(AlarmReminder reminder, bool active) async {
    reminder.isActive = active;
    reminder.done = false;
    if (active) {
      try {
        await AlarmService.requestPermissions();
        await AlarmService.schedule(reminder);
      } catch (_) {
        reminder.isActive = false;
        _message('Exact-alarm permission required.', error: true);
      }
    } else {
      await AlarmService.cancel(reminder.id);
    }
    await widget.store.save();
    if (mounted) setState(() {});
  }

  Future<void> _delete(AlarmReminder reminder) async {
    await AlarmService.cancel(reminder.id);
    widget.store.reminders.removeWhere((e) => e.id == reminder.id);
    await widget.store.save();
    if (mounted) setState(() {});
  }

  void _message(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? cDanger : cDeep,
      ),
    );
  }

  String _repeatLabel(AlarmReminder r) {
    switch (r.repeatType) {
      case RepeatType.daily:
        return 'Every day';
      case RepeatType.once:
        return 'Once';
      case RepeatType.specificDate:
        final d = r.specificDate;
        return d == null
            ? 'Specific date'
            : '${d.day.toString().padLeft(2, '0')}/'
                '${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminders = [...widget.store.reminders]
      ..sort((a, b) =>
          a.nextSystemDateTime.compareTo(b.nextSystemDateTime));

    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: cDeep, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Reminders',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: cDeep,
          ),
        ),
      ),
      body: SafeArea(
        child: reminders.isEmpty
            ? const _EmptyReminders()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
                itemCount: reminders.length,
                itemBuilder: (_, i) {
                  final r = reminders[i];
                  return _ReminderCard(
                    reminder: r,
                    repeatLabel: _repeatLabel(r),
                    onToggle: (v) => _toggle(r, v),
                    onDelete: () => _delete(r),
                    onTap: () => _editReminder(r),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_reminder',
        backgroundColor: cPrimaryDark,
        foregroundColor: Colors.white,
        onPressed: _addViaVoice,
        icon: const Icon(Icons.add_rounded, size: 26),
        label: const Text(
          'New Reminder',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
    );
  }
}

// =============================================================================
// Reminder card — with type icon
// =============================================================================

class _ReminderCard extends StatelessWidget {
  final AlarmReminder reminder;
  final String repeatLabel;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ReminderCard({
    required this.reminder,
    required this.repeatLabel,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = ReminderIcons.iconFor(reminder);
    final bg = ReminderIcons.colorFor(reminder);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: cPrimaryDark, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reminder.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: cText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${reminder.hour.toString().padLeft(2, '0')}:'
                        '${reminder.minute.toString().padLeft(2, '0')} '
                        '${reminder.amPm}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: cPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        repeatLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: cMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: reminder.isActive,
                      onChanged: onToggle,
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: cDanger,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Empty state
// =============================================================================

class _EmptyReminders extends StatelessWidget {
  const _EmptyReminders();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.alarm_add_rounded, size: 64, color: cPrimaryDark),
              SizedBox(height: 12),
              Text(
                'No reminders yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: cDeep,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Tap "+ New Reminder" and speak your reminder.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cMuted, height: 1.4),
              ),
            ],
          ),
        ),
      );
}

// =============================================================================
// Editor dialog
// =============================================================================

class _ReminderEditorDialog extends StatefulWidget {
  final AlarmReminder initial;
  const _ReminderEditorDialog({required this.initial});

  @override
  State<_ReminderEditorDialog> createState() => _ReminderEditorDialogState();
}

class _ReminderEditorDialogState extends State<_ReminderEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _detail;
  late TimeOfDay _time;
  late RepeatType _repeat;
  late DateTime? _specificDate;
  late AlarmType _alarmType;
  late MedicineTiming? _medicineTiming;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _title = TextEditingController(text: init.title);
    _detail = TextEditingController(text: init.detail);
    _time = TimeOfDay(
      hour: init.hour % 12 == 0 ? 12 : init.hour % 12,
      minute: init.minute,
    );
    _repeat = init.repeatType;
    _specificDate = init.specificDate;
    _alarmType = init.alarmType;
    _medicineTiming = init.medicineTiming;
  }

  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'SET ALARM TIME',
      cancelText: 'CANCEL',
      confirmText: 'OK',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      initialDate: _specificDate ?? now,
      helpText: 'SELECT ALARM DATE',
      cancelText: 'CANCEL',
      confirmText: 'SET DATE',
    );
    if (picked != null) setState(() => _specificDate = picked);
  }

  void _selectType(AlarmType type) {
    setState(() {
      _alarmType = type;
      if (type != AlarmType.medicine) _medicineTiming = null;
      if (_title.text.trim().isEmpty) {
        _title.text = switch (type) {
          AlarmType.medicine => 'Medicine',
          AlarmType.food => 'Food',
          AlarmType.memoryActivity => 'Memory Activity',
          AlarmType.customTask => '',
        };
      }
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      _error('Enter a title.');
      return;
    }
    if (_alarmType == AlarmType.medicine && _medicineTiming == null) {
      _error('Medicine requires Before / After Food.');
      return;
    }
    if (_repeat == RepeatType.specificDate && _specificDate == null) {
      _error('Select a calendar date.');
      return;
    }

    final now = DateTime.now();
    final hour24 = _time.period == DayPeriod.pm
        ? (_time.hourOfPeriod == 12 ? 12 : _time.hourOfPeriod + 12)
        : (_time.hourOfPeriod == 12 ? 0 : _time.hourOfPeriod);
    final target = _repeat == RepeatType.specificDate
        ? DateTime(
            _specificDate!.year,
            _specificDate!.month,
            _specificDate!.day,
            hour24,
            _time.minute,
          )
        : DateTime(now.year, now.month, now.day, hour24, _time.minute);
    if (_repeat == RepeatType.specificDate && !target.isAfter(now)) {
      _error('That date has passed.');
      return;
    }

    final lang = widget.initial.language.isNotEmpty
        ? widget.initial.language
        : AuthStore.instance.preferredLanguage.key;

    final updated = AlarmReminder(
      id: widget.initial.id,
      title: title,
      detail: _detail.text.trim(),
      hour: _time.hourOfPeriod == 0 ? 12 : _time.hourOfPeriod,
      minute: _time.minute,
      amPm: _time.period == DayPeriod.pm ? 'PM' : 'AM',
      repeatType: _repeat,
      specificDate: _specificDate,
      alarmType: _alarmType,
      medicineTiming: _medicineTiming,
      isActive: widget.initial.isActive,
      done: false,
      language: lang,
      createdByName: widget.initial.createdByName,
    );
    Navigator.of(context).pop(updated);
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: cDanger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit_rounded, color: cPrimaryDark),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Edit Reminder',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TimeTile(time: _time, onTap: _pickTime),
              const SizedBox(height: 16),
              const Text('Repeat',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, color: cDeep)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ChoiceChip(
                  selected: _repeat == RepeatType.daily,
                  label: const Text('Daily'),
                  onSelected: (_) =>
                      setState(() => _repeat = RepeatType.daily),
                ),
                ChoiceChip(
                  selected: _repeat == RepeatType.once,
                  label: const Text('Once'),
                  onSelected: (_) =>
                      setState(() => _repeat = RepeatType.once),
                ),
                ChoiceChip(
                  selected: _repeat == RepeatType.specificDate,
                  label: const Text('Specific Date'),
                  onSelected: (_) async {
                    setState(() => _repeat = RepeatType.specificDate);
                    await _pickDate();
                  },
                ),
              ]),
              const SizedBox(height: 18),
              const Text('Type',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, color: cDeep)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: AlarmType.values.map((t) {
                final selected = t == _alarmType;
                return ChoiceChip(
                  selected: selected,
                  label: Text(_typeLabel(t)),
                  onSelected: (_) => _selectType(t),
                );
              }).toList()),
              if (_alarmType == AlarmType.medicine) ...[
                const SizedBox(height: 16),
                Wrap(spacing: 8, children: [
                  ChoiceChip(
                    selected: _medicineTiming == MedicineTiming.beforeFood,
                    label: const Text('Before Food'),
                    onSelected: (_) => setState(
                        () => _medicineTiming = MedicineTiming.beforeFood),
                  ),
                  ChoiceChip(
                    selected: _medicineTiming == MedicineTiming.afterFood,
                    label: const Text('After Food'),
                    onSelected: (_) => setState(
                        () => _medicineTiming = MedicineTiming.afterFood),
                  ),
                ]),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                decoration: inputDec('Reminder title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _detail,
                maxLines: 2,
                decoration: inputDec('Notes (optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Update'),
        ),
      ],
    );
  }

  String _typeLabel(AlarmType t) => switch (t) {
        AlarmType.medicine => 'Medicine',
        AlarmType.food => 'Food',
        AlarmType.memoryActivity => 'Memory',
        AlarmType.customTask => 'Task',
      };
}

class _TimeTile extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeTile({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.pm ? 'PM' : 'AM';
    return Material(
      color: cDeep,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.access_time_filled_rounded,
                  color: cSoft, size: 30),
              const SizedBox(width: 14),
              Text(
                '$hour:$minute',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                period,
                style: const TextStyle(
                  color: cSoft,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const Icon(Icons.edit_rounded, color: cSoft),
            ],
          ),
        ),
      ),
    );
  }
}