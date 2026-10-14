import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/auth/auth_store.dart';
import '../../core/domain/app_models.dart';
import '../../core/games/difficulty_optimizer.dart';
import '../../core/games/game_intro_view.dart';
import '../../core/games/game_result_view.dart';
import '../../core/localization/app_languages.dart';
import '../../core/games/game_scoring.dart';
import '../../core/theme/app_theme.dart';
import 'sound_match_game.dart';

class SoundMatchScreen extends StatefulWidget {
  final SmaranStore store;
  const SoundMatchScreen({super.key, required this.store});

  @override
  State<SoundMatchScreen> createState() => _SoundMatchScreenState();
}

class _SoundMatchScreenState extends State<SoundMatchScreen> {
  final _tts = FlutterTts();
  final _gameKey = GlobalKey<SoundMatchGameState>();

  late int _level;
  late int _optionsCount;
  late int _totalRounds;
  bool _playing = false;
  int _finalScore = 0;
  bool _done = false;
  bool _leveledUp = false;

  @override
  void initState() {
    super.initState();
    _recomputeLevel();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _recomputeLevel() {
    _level = DifficultyOptimizer.instance
        .recommendedLevel('sound_match', widget.store.gameSessions);

    switch (_level) {
      case 1:
        _optionsCount = 3;
        _totalRounds = 3;
        break;
      case 2:
        _optionsCount = 3;
        _totalRounds = 4;
        break;
      case 3:
        _optionsCount = 4;
        _totalRounds = 4;
        break;
      case 4:
        _optionsCount = 4;
        _totalRounds = 5;
        break;
      default:
        _optionsCount = 5;
        _totalRounds = 5;
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.setSpeechRate(0.4);
      await _tts.setLanguage(AuthStore.instance.preferredLanguage.localeCode);
      await _tts.speak(text);
    } catch (_) {}
  }

  void _start() {
    setState(() {
      _playing = true;
      _done = false;
      _leveledUp = false;
    });
  }

  void _speakCurrentTarget() {
    final s = _gameKey.currentState;
    if (s != null) _speak(s.targetWord);
  }

  Future<void> _onComplete(SoundMatchResult r) async {
    final oldLevel = _level;
    _finalScore = GameScoring.accuracy(
      correct: r.correctCount,
      total: r.totalRounds,
    );

    widget.store.gameSessions.add(GameSession(
      gameId: 'sound_match',
      score: _finalScore,
      durationSec: r.duration.inSeconds,
      difficulty: _level,
      moves: r.totalRounds,
      timestamp: DateTime.now(),
    ));
    await widget.store.save();

    final newLevel = DifficultyOptimizer.instance
        .recommendedLevel('sound_match', widget.store.gameSessions);
    _leveledUp = newLevel > oldLevel;

    if (!mounted) return;
    setState(() {
      _playing = false;
      _done = true;
    });
    await _speak(_finalScore >= 80 ? 'Great listening!' : 'Nicely done!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: cDeep, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sound Match',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cDeep),
        ),
      ),
      body: SafeArea(
        child: _playing
            ? SoundMatchGame(
                key: _gameKey,
                optionsCount: _optionsCount,
                totalRounds: _totalRounds,
                difficulty: _level,
                onComplete: _onComplete,
                onSpeak: _speak,
                onRoundStart: () {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _speakCurrentTarget();
                  });
                },
              )
            : _done
                ? GameResultView(
                    heroEmoji: '🎧',
                    title: _finalScore >= 80
                        ? 'Great listening!'
                        : 'Nicely done!',
                    score: _finalScore,
                    leveledUp: _leveledUp,
                    infoRows: [
                      GameInfoRowData(
                        icon: Icons.check_circle_rounded,
                        label: 'Correct',
                        value: '$_finalScore%',
                      ),
                      GameInfoRowData(
                        icon: Icons.signal_cellular_alt_rounded,
                        label: 'Level',
                        value: '$_level of 5',
                      ),
                    ],
                    onPlayAgain: () {
                      _recomputeLevel();
                      _start();
                    },
                    onExit: () => Navigator.pop(context),
                  )
                : GameIntroView(
                    heroEmoji: '🎧',
                    title: 'Sound Match',
                    description:
                        'Listen to the word, then tap the matching picture.',
                    level: _level,
                    levelLabel:
                        DifficultyOptimizer.instance.levelLabel(_level),
                    levelColorValue:
                        DifficultyOptimizer.instance.levelColorValue(_level),
                    infoRows: [
                      GameInfoRowData(
                        icon: Icons.volume_up_rounded,
                        label: 'Rounds',
                        value: '$_totalRounds',
                      ),
                    ],
                    onStart: _start,
                  ),
      ),
    );
  }
}