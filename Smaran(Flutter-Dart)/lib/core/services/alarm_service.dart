import 'dart:async';
import 'dart:convert';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../domain/app_models.dart';
import '../localization/app_languages.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> smaranNavigatorKey =
    GlobalKey<NavigatorState>();

const String _alarmChannelId = 'smaran_native_alarm_v3';
const String _alarmChannelName = 'Smaran Alarms';
const String _alarmChannelDescription =
    'Exact reminders and alarm notifications for Smaran.';

const String _alarmRingAsset = 'audio/smaran_alarm_01.mp3';

/* ============================================================================
 * BACKGROUND ALARM CALLBACK
 * ========================================================================== */
@pragma('vm:entry-point')
Future<void> smaranAlarmCallback(
  int id,
  Map<String, dynamic> params,
) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AndroidAlarmManager.initialize();

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _alarmChannelId,
        _alarmChannelName,
        description: _alarmChannelDescription,
        importance: Importance.max,
        playSound: false,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      ),
    );

    await _showAlarmNotificationWithPlugin(plugin, params);

    if (params['repeatType']?.toString() == RepeatType.daily.name) {
      final next = _nextDailyFromParams(params);
      if (next != null) {
        await AndroidAlarmManager.oneShotAt(
          next,
          id,
          smaranAlarmCallback,
          alarmClock: true,
          allowWhileIdle: true,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          params: params,
        );
      }
    } else {
      await _markOneShotInactive(id);
    }
  } catch (_) {}
}

/* ============================================================================
 * ALARM SERVICE
 * ========================================================================== */
class AlarmService {
  AlarmService._();

  static final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  static Map<String, dynamic>? _pendingAlarm;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await AndroidAlarmManager.initialize();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final android = notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _alarmChannelId,
        _alarmChannelName,
        description: _alarmChannelDescription,
        importance: Importance.max,
        playSound: false,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      ),
    );

    final launchDetails =
        await notifications.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        _pendingAlarm = _decodePayload(payload);
      }
    }
  }

  static Future<void> requestPermissions() async {
    final android = notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    await android?.requestFullScreenIntentPermission();
  }

  static Future<void> schedule(AlarmReminder reminder) async {
    if (!reminder.isActive) return;
    await cancel(reminder.id);

    final target = reminder.nextSystemDateTime;
    if (!target.isAfter(DateTime.now())) return;

    reminder.systemTimeStamp = DateTime.now().millisecondsSinceEpoch;

    // The reminder carries its own language. No global lookup needed.
    final params = <String, dynamic>{
      'id': reminder.id,
      'title': reminder.title,
      'detail': reminder.detail,
      'hour': reminder.hour,
      'minute': reminder.minute,
      'amPm': reminder.amPm,
      'repeatType': reminder.repeatType.name,
      'specificDate': reminder.specificDate?.millisecondsSinceEpoch,
      'alarmType': reminder.alarmType.name,
      'medicineTiming': reminder.medicineTiming?.name,
      'language': reminder.language,  // ← the reminder's own language
      'smaran_alarm_launch': true,
    };

    await AndroidAlarmManager.oneShotAt(
      target,
      reminder.id,
      smaranAlarmCallback,
      alarmClock: true,
      allowWhileIdle: true,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: params,
    );
  }

  static Future<void> cancel(int id) async {
    await AndroidAlarmManager.cancel(id);
    await notifications.cancel(id: id);
  }

  static Future<void> rescheduleAll(Iterable<AlarmReminder> reminders) async {
    for (final reminder in reminders) {
      if (reminder.isActive && !reminder.done) {
        try {
          await schedule(reminder);
        } catch (_) {}
      }
    }
  }

  static Future<void> openPendingAlarm() async {
    final payload = _pendingAlarm;
    _pendingAlarm = null;
    if (payload == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      smaranNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AlarmScreen(payload: payload),
        ),
      );
    });
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    final decoded = _decodePayload(payload);
    if (decoded == null) return;

    final navigator = smaranNavigatorKey.currentState;
    if (navigator == null) {
      _pendingAlarm = decoded;
      return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => AlarmScreen(payload: decoded),
      ),
    );
  }

  static Map<String, dynamic>? _decodePayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }
}

/* ============================================================================
 * NOTIFICATION TEXT — generic header, user-language body
 * ========================================================================== */
Future<void> _showAlarmNotificationWithPlugin(
  FlutterLocalNotificationsPlugin plugin,
  Map<String, dynamic> params,
) async {
  final languageKey = params['language']?.toString() ?? 'english';
  final alarmType = params['alarmType']?.toString() ?? 'customTask';
  final medicineTiming = params['medicineTiming']?.toString();

  // Header is always "Smaran Alarm" (brand), body carries the user's text.
  final title = _notifHeaderFor(languageKey);
  final medicine = (alarmType == 'medicine' && medicineTiming != null)
      ? ' • ${medicineTiming == 'beforeFood' ? _beforeFood(languageKey) : _afterFood(languageKey)}'
      : '';

  final reminderTitle = params['title']?.toString() ?? 'Reminder';
  final reminderDetail = params['detail']?.toString() ?? '';
  final body = reminderDetail.isEmpty
      ? '$reminderTitle$medicine'
      : '$reminderTitle$medicine\n$reminderDetail';

  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      _alarmChannelId,
      _alarmChannelName,
      channelDescription: _alarmChannelDescription,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      playSound: false,
      enableVibration: true,
      autoCancel: false,
      ongoing: true,
      visibility: NotificationVisibility.public,
      showWhen: true,
      styleInformation: BigTextStyleInformation(''),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'dismiss',
          'I Understand',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    ),
  );

  final payload = jsonEncode(params);
  final notificationId =
      (params['id'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

  await plugin.show(
    id: notificationId,
    title: title,
    body: body,
    notificationDetails: details,
    payload: payload,
  );
}

String _notifHeaderFor(String key) {
  switch (key) {
    case 'assamese':
      return 'স্মৰণ এলাৰ্ম';
    case 'bengali':
      return 'স্মরণ অ্যালার্ম';
    case 'hindi':
      return 'स्मरण अलार्म';
    case 'nepali':
      return 'स्मरण अलार्म';
    case 'meitei':
      return 'স্মরণ অলার্ম';
    default:
      return 'Smaran Alarm';
  }
}

String _beforeFood(String key) {
  switch (key) {
    case 'assamese':
      return 'খোৱাৰ আগতে';
    case 'bengali':
      return 'খাবারের আগে';
    case 'hindi':
    case 'nepali':
      return 'खाने से पहले';
    default:
      return 'Before food';
  }
}

String _afterFood(String key) {
  switch (key) {
    case 'assamese':
      return 'খোৱাৰ পিছত';
    case 'bengali':
      return 'খাবারের পরে';
    case 'hindi':
    case 'nepali':
      return 'खाने के बाद';
    default:
      return 'After food';
  }
}

/* ============================================================================
 * MARK ONE-SHOT INACTIVE
 * ========================================================================== */
Future<void> _markOneShotInactive(int id) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('reminders') ?? '[]';
    final decoded = jsonDecode(raw);
    if (decoded is! List) return;

    final updated = decoded.map((entry) {
      if (entry is Map && (entry['id'] as num?)?.toInt() == id) {
        final copy = Map<String, dynamic>.from(entry);
        copy['isActive'] = false;
        return copy;
      }
      return entry;
    }).toList();

    await prefs.setString('reminders', jsonEncode(updated));
  } catch (_) {}
}

DateTime? _nextDailyFromParams(Map<String, dynamic> params) {
  final hour = (params['hour'] as num?)?.toInt() ?? 8;
  final minute = (params['minute'] as num?)?.toInt() ?? 0;
  final amPm = params['amPm']?.toString() ?? 'AM';

  final hour24 = amPm.toUpperCase() == 'PM'
      ? (hour == 12 ? 12 : hour + 12)
      : (hour == 12 ? 0 : hour);

  final now = DateTime.now();
  var next = DateTime(now.year, now.month, now.day, hour24, minute);
  if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
  return next;
}

@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {}

/* ============================================================================
 * ALARM SCREEN — full-screen sound + mild vibration + MULTILINGUAL voice
 * ========================================================================== */
class AlarmScreen extends StatefulWidget {
  final Map<String, dynamic> payload;
  const AlarmScreen({super.key, required this.payload});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _ringPlayer = AudioPlayer();

  bool _speaking = false;
  bool _ringPlaying = false;
  Timer? _vibrationTimer;

  String get title =>
      widget.payload['title']?.toString() ?? 'Smaran Reminder';

  String get detail =>
      widget.payload['detail']?.toString() ?? 'It is time for your reminder.';

  /// The language key stored on the reminder (e.g. 'bengali', 'hindi').
  String get languageKey =>
      widget.payload['language']?.toString() ?? 'english';

  /// The AppLanguage enum from the key.
  AppLanguage get language => parseLanguage(languageKey);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAlarm());
  }

  Future<void> _startAlarm() async {
    await _startRing();
    _startVibration();
    await Future.delayed(const Duration(milliseconds: 800));
    await _speak();
  }

  Future<void> _startRing() async {
    if (_ringPlaying) return;
    _ringPlaying = true;
    try {
      await _ringPlayer.setReleaseMode(ReleaseMode.loop);
      await _ringPlayer.setVolume(1.0);
      await _ringPlayer.play(AssetSource(_alarmRingAsset));
    } catch (_) {
      _ringPlaying = false;
    }
  }

  Future<void> _stopRing() async {
    try {
      await _ringPlayer.stop();
    } catch (_) {}
    _ringPlaying = false;
  }

  void _startVibration() {
    _vibrationTimer?.cancel();
    _pulseVibration();
    _vibrationTimer = Timer.periodic(
      const Duration(milliseconds: 1500),
      (_) => _pulseVibration(),
    );
  }

  void _pulseVibration() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  void _stopVibration() {
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
  }

  // ---------------------------------------------------------------------------
  // SPEAK — uses the reminder's own language
  // ---------------------------------------------------------------------------
  Future<void> _speak() async {
    if (_speaking) return;
    _speaking = true;

    try {
      await _tts.setSpeechRate(0.43);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Try the reminder's language first, then fall back to English.
      final targetLocale = language.localeCode;
      bool applied = false;

      try {
        final result = await _tts.setLanguage(targetLocale);
        // Some TTS engines return 1 on success, 0 or null on failure.
        applied = result != null && result != 0;
      } catch (_) {
        applied = false;
      }

      if (!applied) {
        // Try a broader match — just the language part (e.g., "as" instead of "as-IN").
        final langOnly = targetLocale.split('-').first;
        try {
          final result = await _tts.setLanguage(langOnly);
          applied = result != null && result != 0;
        } catch (_) {}
      }

      if (!applied) {
        try {
          await _tts.setLanguage('en-IN');
        } catch (_) {
          try {
            await _tts.setLanguage('en-US');
          } catch (_) {}
        }
      }

      // Build the message in the reminder's language.
      final type = widget.payload['alarmType']?.toString() ?? 'customTask';
      final timing = widget.payload['medicineTiming']?.toString();
      final medicine = _medicinePhrase(languageKey, type, timing);

      final prefix = _voicePrefix(languageKey);

      await _tts.speak('$prefix $title. $detail.$medicine');
    } catch (_) {
    } finally {
      _speaking = false;
    }
  }

  String _voicePrefix(String key) {
    switch (key) {
      case 'assamese':
        return 'স্মৰণ সোঁৱৰণী।';
      case 'bengali':
        return 'স্মরণ রিমাইন্ডার।';
      case 'hindi':
        return 'स्मरण रिमाइंडर।';
      case 'nepali':
        return 'स्मरण रिमाइंडर।';
      case 'meitei':
        return 'স্মরণ ৱাখল।';
      case 'bodo':
        return 'স्मরণ रिमाइंडर।';
      default:
        return 'Smaran reminder.';
    }
  }

  String _medicinePhrase(String key, String type, String? timing) {
    if (type != 'medicine' || timing == null) return '';
    final before = timing == 'beforeFood';
    switch (key) {
      case 'assamese':
        return before ? ' খোৱাৰ আগতে।' : ' খোৱাৰ পিছত।';
      case 'bengali':
        return before ? ' খাবারের আগে।' : ' খাবারের পরে।';
      case 'hindi':
      case 'nepali':
        return before ? ' खाने से पहले।' : ' खाने के बाद।';
      default:
        return before ? ' Before food.' : ' After food.';
    }
  }

  Future<void> _dismiss() async {
    final id = (widget.payload['id'] as num?)?.toInt();
    if (id != null) {
      await AlarmService.notifications.cancel(id: id);
    }
    _stopVibration();
    await _stopRing();
    await _tts.stop();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _stopVibration();
    _tts.stop();
    _stopRing();
    _ringPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: cDeep,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 56,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Icon(Icons.alarm_rounded, color: cSoft, size: 80),
                    const SizedBox(height: 24),
                    const Text(
                      'Smaran Reminder',
                      style: TextStyle(
                        color: cSoft,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      detail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 42),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        onPressed: _dismiss,
                        style: FilledButton.styleFrom(
                          backgroundColor: cPrimary,
                        ),
                        child: const Text(
                          'I Understand',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _speak,
                      icon: const Icon(Icons.volume_up_rounded, color: cSoft),
                      label: const Text(
                        'Hear Again',
                        style: TextStyle(
                          color: cSoft,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}