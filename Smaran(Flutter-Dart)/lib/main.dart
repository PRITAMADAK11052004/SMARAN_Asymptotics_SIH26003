import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'core/auth/auth_store.dart';
import 'core/domain/app_models.dart';
import 'core/services/alarm_service.dart';
import 'core/services/radio_browser_service.dart';
import 'core/services/radio_player_service.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/root_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.smaran_flutter.radio',
      androidNotificationChannelName: 'Smaran Radio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    );
    await RadioPlayerService.instance.init();
    // ignore: avoid_print
    print('[Smaran] Radio background initialized.');
  } catch (e) {
    // ignore: avoid_print
    print('[Smaran] Radio init failed: $e');
  }

  await AlarmService.initialize();
  await AuthStore.instance.boot();
  await RadioBrowserService.instance.init();

  runApp(const SmaranApp());
}

class SmaranApp extends StatefulWidget {
  const SmaranApp({super.key});

  @override
  State<SmaranApp> createState() => _SmaranAppState();
}

class _SmaranAppState extends State<SmaranApp> {
  late final SmaranStore _smaranStore;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _smaranStore = SmaranStore();
    _boot();
  }

  Future<void> _boot() async {
    await _smaranStore.load();
    await AlarmService.rescheduleAll(_smaranStore.reminders);
    if (!mounted) return;
    setState(() => _ready = true);
    await AlarmService.openPendingAlarm();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smaran',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: cPrimary,
          brightness: Brightness.light,
        ),
        fontFamily: 'sans-serif',
      ),
      navigatorKey: smaranNavigatorKey,
      home: !_ready
          ? const Scaffold(
              backgroundColor: cBg,
              body: Center(
                child: CircularProgressIndicator(color: cPrimary),
              ),
            )
          : RootGate(store: _smaranStore),
    );
  }
}