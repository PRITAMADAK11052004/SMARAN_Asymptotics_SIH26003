import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_store.dart';
import '../../core/domain/app_models.dart';
import '../../core/localization/app_localizations.dart';
import '../profile/profile_screen.dart';
import '../reminders/reminder_screen.dart';

// =============================================================================
// Design tokens
// =============================================================================
const _cBg = Color(0xFFFEF7E8);
const _cWhite = Color(0xFFFFFDFC);
const _cPrimaryDark = Color(0xFF4F743D);
const _cPrimarySoft = Color(0xFFE5F0D8);
const _cText = Color(0xFF26332E);
const _cMuted = Color(0xFF6D746E);
const _cBorder = Color(0xFFE6DED0);
const _cDanger = Color(0xFFC64A4A);
const _shadowColor = Color(0x1A7A694E);

// =============================================================================
// Feature tile data
// =============================================================================
class _FeatureItem {
  final String key;
  final String iconAsset;
  final String title;
  final String subtitle;
  final Color background;
  final String route;
  const _FeatureItem({
    required this.key,
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.background,
    required this.route,
  });
}

List<_FeatureItem> _buildFeatureData(L l) => [
      _FeatureItem(
        key: 'daily',
        iconAsset: 'assets/icons/daily_task.svg',
        title: l.yourDailyTask,
        subtitle: l.dailyTaskSub,
        background: _cPrimarySoft,
        route: 'games',
      ),
      _FeatureItem(
        key: 'garden',
        iconAsset: 'assets/icons/memory_garden.svg',
        title: l.memoryGarden,
        subtitle: l.memoryGardenSub,
        background: const Color(0xFFF6DCDD),
        route: 'talk',
      ),
      _FeatureItem(
        key: 'lane',
        iconAsset: 'assets/icons/take_a_trip_down_to_your_memory-lane.svg',
        title: l.memoryLane,
        subtitle: l.memoryLaneSub,
        background: const Color(0xFFDCECF2),
        route: 'photos',
      ),
      _FeatureItem(
        key: 'scheduled',
        iconAsset: 'assets/icons/scheduled.svg',
        title: l.scheduled,
        subtitle: l.scheduledSub,
        background: const Color(0xFFF5E6C7),
        route: 'reminders',
      ),
    ];

// =============================================================================
// HOME SCREEN
// =============================================================================
class HomeScreen extends StatefulWidget {
  final SmaranStore store;
  final ValueChanged<String> onNavigate;
  final ValueChanged<String> onOpenFeature;

  const HomeScreen({
    super.key,
    required this.store,
    required this.onNavigate,
    required this.onOpenFeature,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _imagePicker = ImagePicker();
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_rebuild);
    AuthStore.instance.addListener(_rebuild);
    _tick();
  }

  @override
  void dispose() {
    widget.store.removeListener(_rebuild);
    AuthStore.instance.removeListener(_rebuild);
    _searchController.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _tick() async {
    await Future.delayed(const Duration(seconds: 30));
    if (!mounted) return;
    setState(() => _now = DateTime.now());
    _tick();
  }

  String get _firstName {
    final user = AuthStore.instance.currentUser;
    final raw = (user?.fullName ?? widget.store.patientName).trim();
    if (raw.isEmpty) return 'Patient';
    return raw.split(RegExp(r'\s+')).first;
  }

  String get _greeting {
    final l = L.current;
    final h = _now.hour;
    if (h >= 5 && h < 12) return l.goodMorning;
    if (h >= 12 && h < 17) return l.goodAfternoon;
    return l.goodEvening;
  }

  bool get _isDaytime => _now.hour >= 6 && _now.hour < 18;

  String get _formattedDate {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${weekdays[_now.weekday - 1]}, '
        '${months[_now.month - 1]} ${_now.day}, ${_now.year}';
  }

  List<AlarmReminder> get _activeReminders {
    final list = widget.store.reminders
        .where((r) => r.isActive && !r.done)
        .toList();
    list.sort((a, b) => a.nextSystemDateTime.compareTo(b.nextSystemDateTime));
    return list;
  }

  List<AlarmReminder> get _todayPlan => _activeReminders.take(2).toList();
  int get _pendingCount => _activeReminders.length;
  int get _completedGamesCount => widget.store.gamesCompletedToday();

  Future<void> _openReminders() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RemindersScreen(store: widget.store)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    if (mounted) setState(() {});
  }

  void _handleFeaturePress(_FeatureItem item) {
    switch (item.route) {
      case 'games':
        widget.onOpenFeature('games');
        break;
      case 'talk':
        widget.onOpenFeature('talk');
        break;
      case 'photos':
        widget.onNavigate('photos');
        break;
      case 'reminders':
        _openReminders();
        break;
    }
  }

  void _handleMicrophone() => widget.onOpenFeature('talk');

  Future<void> _handleCamera() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (!mounted || image == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo captured. Smaran can use it for memory search.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera is not available right now.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.current;
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final h = media.size.height;
    final scale = math.min(w / 449.0, h / 900.0).clamp(0.92, 1.10);

    // Consistent spacing — same gap everywhere in the plan section.
    final gap = 12 * scale;

    return Scaffold(
      backgroundColor: _cBg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16 * scale, 14 * scale, 16 * scale, 16 * scale,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AnimatedEntry(
                delayMs: 40,
                child: _Header(
                  scale: scale,
                  firstName: _firstName,
                  greeting: _greeting,
                  isDaytime: _isDaytime,
                  date: _formattedDate,
                  pendingCount: _pendingCount,
                  onBellTap: _openReminders,
                  onProfileTap: _openProfile,
                ),
              ),

              _FeatureGrid(
                scale: scale,
                items: _buildFeatureData(l),
                onTap: _handleFeaturePress,
              ),

              SizedBox(height: gap),

              _AnimatedEntry(
                delayMs: 570,
                child: _ProgressBanner(
                  scale: scale,
                  completed: _completedGamesCount,
                  onTap: () => widget.onOpenFeature('games'),
                ),
              ),

              SizedBox(height: 16 * scale),

              _AnimatedEntry(
                delayMs: 650,
                child: _PlanHeader(
                  scale: scale,
                  onFullSchedule: _openReminders,
                ),
              ),

              SizedBox(height: 10 * scale),

              // ── Today's Plan list ──────────────────────────
              if (_todayPlan.isEmpty)
                _AnimatedEntry(
                  delayMs: 720,
                  child: _EmptyPlan(scale: scale, onAdd: _openReminders),
                )
              else
                for (int i = 0; i < _todayPlan.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: gap),
                    child: _AnimatedEntry(
                      delayMs: 720 + (i * 100),
                      child: _PlanCard(
                        scale: scale,
                        reminder: _todayPlan[i],
                      ),
                    ),
                  ),

              // ── AI search bar — SAME gap as between cards ──
              _AnimatedEntry(
                delayMs: 900,
                child: _AiReminderSection(
                  scale: scale,
                  controller: _searchController,
                  onMicrophone: _handleMicrophone,
                  onCamera: _handleCamera,
                  onSubmit: (_) => widget.onOpenFeature('talk'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Animated entry wrapper
// =============================================================================
class _AnimatedEntry extends StatefulWidget {
  final int delayMs;
  final Widget child;

  const _AnimatedEntry({
    required this.child,
    this.delayMs = 0,
  });

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => Opacity(
          opacity: _opacity.value,
          child: FractionalTranslation(
            translation: _slide.value,
            child: child,
          ),
        ),
        child: widget.child,
      );
}

// =============================================================================
// HEADER
// =============================================================================
class _Header extends StatelessWidget {
  final double scale;
  final String firstName;
  final String greeting;
  final bool isDaytime;
  final String date;
  final int pendingCount;
  final VoidCallback onBellTap;
  final VoidCallback onProfileTap;

  const _Header({
    required this.scale,
    required this.firstName,
    required this.greeting,
    required this.isDaytime,
    required this.date,
    required this.pendingCount,
    required this.onBellTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.current;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.hello,
                style: TextStyle(
                  fontSize: 31 * scale,
                  height: 36 / 31,
                  fontWeight: FontWeight.w700,
                  color: _cText,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(
                height: 45 * scale,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      firstName,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 40 * scale,
                        height: 45 / 40,
                        fontWeight: FontWeight.w900,
                        color: _cPrimaryDark,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 7 * scale),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18 * scale,
                        height: 23 / 18,
                        fontWeight: FontWeight.w800,
                        color: _cText,
                      ),
                    ),
                  ),
                  SizedBox(width: 7 * scale),
                  Text(
                    isDaytime ? '☀️' : '🌙',
                    style: TextStyle(fontSize: 19 * scale),
                  ),
                ],
              ),
              SizedBox(height: 2 * scale),
              Text(
                date,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12 * scale,
                  height: 17 / 12,
                  fontWeight: FontWeight.w600,
                  color: _cMuted,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8 * scale),
        Material(
          color: _cWhite,
          borderRadius: BorderRadius.circular(20 * scale),
          elevation: 3,
          shadowColor: _shadowColor,
          child: InkWell(
            onTap: onBellTap,
            borderRadius: BorderRadius.circular(20 * scale),
            child: SizedBox(
              width: 52 * scale,
              height: 52 * scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 26 * scale,
                    color: _cPrimaryDark,
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: 4 * scale,
                      top: 4 * scale,
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: 18 * scale,
                          minHeight: 18 * scale,
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 4 * scale),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _cDanger,
                          borderRadius: BorderRadius.circular(10 * scale),
                          border: Border.all(color: _cWhite, width: 1.5),
                        ),
                        child: Text(
                          pendingCount > 9 ? '9' : '$pendingCount',
                          style: TextStyle(
                            fontSize: 9 * scale,
                            color: _cWhite,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 8 * scale),
        Material(
          color: _cWhite,
          borderRadius: BorderRadius.circular(20 * scale),
          elevation: 3,
          shadowColor: _shadowColor,
          child: InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(20 * scale),
            child: SizedBox(
              width: 52 * scale,
              height: 52 * scale,
              child: Icon(
                Icons.person_outline_rounded,
                size: 26 * scale,
                color: _cPrimaryDark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// FEATURE GRID
// =============================================================================
class _FeatureGrid extends StatelessWidget {
  final double scale;
  final List<_FeatureItem> items;
  final ValueChanged<_FeatureItem> onTap;

  const _FeatureGrid({
    required this.scale,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 4 * scale : 12 * scale),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _AnimatedEntry(
                    delayMs: 160 + (i * 90),
                    child: _FeatureTile(
                      scale: scale,
                      item: items[i],
                      onTap: () => onTap(items[i]),
                    ),
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: i + 1 < items.length
                      ? _AnimatedEntry(
                          delayMs: 160 + ((i + 1) * 90),
                          child: _FeatureTile(
                            scale: scale,
                            item: items[i + 1],
                            onTap: () => onTap(items[i + 1]),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final double scale;
  final _FeatureItem item;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.scale,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cWhite,
      elevation: 3,
      shadowColor: _shadowColor,
      borderRadius: BorderRadius.circular(21 * scale),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21 * scale),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 142 * scale),
          child: Padding(
            padding: EdgeInsets.all(11 * scale),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46 * scale,
                      height: 46 * scale,
                      decoration: BoxDecoration(
                        color: item.background,
                        borderRadius: BorderRadius.circular(16 * scale),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(11 * scale),
                        child: SvgPicture.asset(
                          item.iconAsset,
                          colorFilter: const ColorFilter.mode(
                            _cPrimaryDark,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 11 * scale),
                    Padding(
                      padding: EdgeInsets.only(right: 16 * scale),
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16 * scale,
                          height: 20 / 16,
                          fontWeight: FontWeight.w900,
                          color: _cText,
                        ),
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Padding(
                      padding: EdgeInsets.only(right: 5 * scale),
                      child: Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5 * scale,
                          height: 14 / 10.5,
                          fontWeight: FontWeight.w600,
                          color: _cMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Text(
                    '›',
                    style: TextStyle(
                      fontSize: 27 * scale,
                      height: 1,
                      color: _cText,
                    ),
                  ),
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
// PROGRESS BANNER — thinner, correct interpolation
// =============================================================================
class _ProgressBanner extends StatelessWidget {
  final double scale;
  final int completed;
  final VoidCallback onTap;

  const _ProgressBanner({
    required this.scale,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // FIXED: no "1 5 of 5". Uses only `completed`.
    final text = '${L.current.greatJobPrefix} $completed ${L.current.ofGamesToday}';

    return Material(
      color: const Color(0xFFE2F1D6),
      borderRadius: BorderRadius.circular(18 * scale),
      elevation: 2,
      shadowColor: _shadowColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18 * scale),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scale,
            vertical: 10 * scale,
          ),
          child: Row(
            children: [
              Container(
                width: 42 * scale,
                height: 42 * scale,
                decoration: const BoxDecoration(
                  color: Color(0xFFD8EAC9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  size: 22 * scale,
                  color: _cPrimaryDark,
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 5 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5 * scale,
                          height: 17 / 13.5,
                          fontWeight: FontWeight.w900,
                          color: _cPrimaryDark,
                        ),
                      ),
                      SizedBox(height: 1 * scale),
                      Text(
                        L.current.keepMindActive,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10 * scale,
                          height: 13 / 10,
                          fontWeight: FontWeight.w700,
                          color: _cMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                '›',
                style: TextStyle(
                  fontSize: 26 * scale,
                  height: 1,
                  color: _cPrimaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TODAY'S PLAN HEADER
// =============================================================================
class _PlanHeader extends StatelessWidget {
  final double scale;
  final VoidCallback onFullSchedule;

  const _PlanHeader({required this.scale, required this.onFullSchedule});

  @override
  Widget build(BuildContext context) {
    final l = L.current;
    return Row(
      children: [
        Expanded(
          child: Text(
            l.todaysPlan,
            style: TextStyle(
              fontSize: 26 * scale,
              height: 31 / 26,
              fontWeight: FontWeight.w900,
              color: _cText,
            ),
          ),
        ),
        InkWell(
          onTap: onFullSchedule,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 7 * scale,
              vertical: 5 * scale,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 18 * scale,
                  color: _cPrimaryDark,
                ),
                SizedBox(width: 5 * scale),
                Text(
                  l.fullSchedule,
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: _cPrimaryDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PLAN CARD — type-specific icon, display-only, no toggle
// =============================================================================

class _PlanCard extends StatelessWidget {
  final double scale;
  final AlarmReminder reminder;

  const _PlanCard({
    required this.scale,
    required this.reminder,
  });

  /// Return the icon for this reminder based on its type.
  /// For custom tasks, we infer from the title's keywords.
  IconData get _typeIcon {
    if (reminder.alarmType == AlarmType.medicine) {
      return Icons.medication_rounded;
    }
    if (reminder.alarmType == AlarmType.food) {
      return Icons.restaurant_rounded;
    }
    if (reminder.alarmType == AlarmType.memoryActivity) {
      return Icons.psychology_rounded;
    }

    // Custom task — infer from title
    final t = reminder.title.toLowerCase();
    if (t.contains('water') ||
        t.contains('drink') ||
        t.contains('hydrat') ||
        t.contains('পানি') ||
        t.contains('জল') ||
        t.contains('पानी')) {
      return Icons.local_drink_rounded;
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

  /// Background color for the icon circle.
  Color get _typeColor {
    if (reminder.alarmType == AlarmType.medicine) {
      return const Color(0xFFE5F0D8);
    }
    if (reminder.alarmType == AlarmType.food) {
      return const Color(0xFFF5E6C7);
    }
    if (reminder.alarmType == AlarmType.memoryActivity) {
      return const Color(0xFFF6DCDD);
    }

    final t = reminder.title.toLowerCase();
    if (t.contains('water') ||
        t.contains('drink') ||
        t.contains('hydrat') ||
        t.contains('পানি') ||
        t.contains('जल') ||
        t.contains('पानी')) {
      return const Color(0xFFDCECF2);
    }
    if (t.contains('music') ||
        t.contains('song') ||
        t.contains('radio') ||
        t.contains('গান') ||
        t.contains('संगीत')) {
      return const Color(0xFFECE6F1);
    }
    return const Color(0xFFE4F1D8);
  }

  String get _timeLabel {
    var hour = reminder.hour;
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    return '$hour:${reminder.minute.toString().padLeft(2, '0')} '
        '${reminder.amPm.toUpperCase()}';
  }

  String get _detailLabel {
    final d = reminder.detail.trim();
    if (d.isEmpty) return L.current.smaranReminder;
    return d;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cWhite,
      borderRadius: BorderRadius.circular(16 * scale),
      elevation: 2,
      shadowColor: _shadowColor,
      child: Container(
        padding: EdgeInsets.all(14 * scale),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(color: _cBorder, width: 1.1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Type-specific icon circle ─────────────────
            Container(
              width: 46 * scale,
              height: 46 * scale,
              decoration: BoxDecoration(
                color: _typeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _typeIcon,
                size: 24 * scale,
                color: _cPrimaryDark,
              ),
            ),

            SizedBox(width: 14 * scale),

            // ── Time + Title + Detail ────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _timeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13 * scale,
                      height: 16 / 13,
                      fontWeight: FontWeight.w900,
                      color: _cPrimaryDark,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 3 * scale),
                  Text(
                    reminder.title.isEmpty
                        ? L.current.smaranReminder
                        : reminder.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5 * scale,
                      height: 19 / 15.5,
                      fontWeight: FontWeight.w900,
                      color: _cText,
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    _detailLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5 * scale,
                      height: 15 / 11.5,
                      fontWeight: FontWeight.w600,
                      color: _cMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// EMPTY PLAN
// =============================================================================
class _EmptyPlan extends StatelessWidget {
  final double scale;
  final VoidCallback onAdd;

  const _EmptyPlan({required this.scale, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l = L.current;
    return Material(
      color: _cWhite,
      borderRadius: BorderRadius.circular(16 * scale),
      elevation: 2,
      shadowColor: _shadowColor,
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(16 * scale),
        child: Padding(
          padding: EdgeInsets.all(16 * scale),
          child: Row(
            children: [
              Container(
                width: 46 * scale,
                height: 46 * scale,
                decoration: const BoxDecoration(
                  color: _cPrimarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 22 * scale,
                  color: _cPrimaryDark,
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.nothingScheduled,
                      style: TextStyle(
                        fontSize: 15 * scale,
                        fontWeight: FontWeight.w900,
                        color: _cText,
                      ),
                    ),
                    SizedBox(height: 3 * scale),
                    Text(
                      l.addReminderHint,
                      style: TextStyle(
                        fontSize: 11 * scale,
                        height: 14 / 11,
                        color: _cMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '›',
                style: TextStyle(
                  fontSize: 24 * scale,
                  height: 1,
                  color: _cPrimaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// AI REMINDER COMPOSER
// =============================================================================
class _AiReminderSection extends StatelessWidget {
  final double scale;
  final TextEditingController controller;
  final VoidCallback onMicrophone;
  final VoidCallback onCamera;
  final ValueChanged<String> onSubmit;

  const _AiReminderSection({
    required this.scale,
    required this.controller,
    required this.onMicrophone,
    required this.onCamera,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.current;
    return Material(
      color: _cWhite,
      borderRadius: BorderRadius.circular(31 * scale),
      elevation: 3,
      shadowColor: _shadowColor,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(31 * scale),
          border: Border.all(color: const Color(0xFFE8E1D5)),
        ),
        padding: EdgeInsets.only(
          left: 13 * scale,
          right: 6 * scale,
          top: 4 * scale,
          bottom: 4 * scale,
        ),
        child: Row(
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 23 * scale,
              color: _cPrimaryDark,
            ),
            SizedBox(width: 8 * scale),
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: onSubmit,
                textInputAction: TextInputAction.send,
                style: TextStyle(fontSize: 15 * scale, color: _cText),
                decoration: InputDecoration(
                  hintText: l.askReminders,
                  hintStyle: TextStyle(fontSize: 14 * scale, color: _cMuted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12 * scale),
                ),
              ),
            ),
            _ComposerActionButton(
              icon: Icons.mic_none_rounded,
              background: const Color(0xFFE5F2DA),
              border: const Color(0xFFD4E5C8),
              scale: scale,
              onTap: onMicrophone,
            ),
            SizedBox(width: 4 * scale),
            _ComposerActionButton(
              icon: Icons.camera_alt_outlined,
              background: const Color(0xFFF7F8F1),
              border: const Color(0xFFE0E6D8),
              scale: scale,
              onTap: onCamera,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerActionButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color border;
  final double scale;
  final VoidCallback onTap;

  const _ComposerActionButton({
    required this.icon,
    required this.background,
    required this.border,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44 * scale,
          height: 44 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: 22 * scale, color: _cPrimaryDark),
        ),
      ),
    );
  }
}