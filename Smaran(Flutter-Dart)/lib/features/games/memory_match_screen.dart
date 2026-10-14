import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/auth/auth_store.dart';
import '../../core/domain/app_models.dart';
import '../../core/games/difficulty_optimizer.dart';
import '../../core/games/game_intro_view.dart';
import '../../core/games/game_result_view.dart';
import '../../core/games/game_scoring.dart';
import '../../core/localization/app_languages.dart';
import '../../core/theme/app_theme.dart';
import 'memory_match_game.dart';

class MemoryMatchScreen extends StatefulWidget {
  final SmaranStore store;
  const MemoryMatchScreen({super.key, required this.store});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  final FlutterTts _tts = FlutterTts();

  late int _level;
  late int _pairs;
  MemoryGameResult? _result;
  bool _playing = false;
  int _finalScore = 0;
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
        .recommendedLevel('memory_match', widget.store.gameSessions);

    switch (_level) {
      case 1:
        _pairs = 3;
        break;
      case 2:
        _pairs = 4;
        break;
      case 3:
        _pairs = 6;
        break;
      case 4:
        _pairs = 8;
        break;
      default:
        _pairs = 10;
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.setSpeechRate(0.43);
      await _tts.setVolume(1.0);
      await _tts.setLanguage(AuthStore.instance.preferredLanguage.localeCode);
      await _tts.speak(text);
    } catch (_) {}
  }

  void _startGame() {
    setState(() {
      _result = null;
      _leveledUp = false;
      _playing = true;
    });
    _speak('Let\'s begin. Find the matching pairs.');
  }

  Future<void> _onGameComplete(MemoryGameResult r) async {
    final oldLevel = _level;
    _finalScore = GameScoring.memoryMatch(moves: r.moves, pairs: r.pairs);

    widget.store.gameSessions.add(GameSession(
      gameId: 'memory_match',
      score: _finalScore,
      durationSec: r.duration.inSeconds,
      difficulty: _level,
      moves: r.moves,
      timestamp: DateTime.now(),
    ));
    await widget.store.save();

    final newLevel = DifficultyOptimizer.instance
        .recommendedLevel('memory_match', widget.store.gameSessions);
    _leveledUp = newLevel > oldLevel;

    if (!mounted) return;
    setState(() {
      _playing = false;
      _result = r;
    });

    await _speak(_finalScore >= 80
        ? 'Wonderful! You remembered every pair.'
        : 'Great effort. Let\'s try again soon.');
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Memory Match',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: cDeep,
          ),
        ),
      ),
      body: SafeArea(
        child: _playing
            ? MemoryMatchGame(
                pairs: _pairs,
                difficulty: _level,
                onComplete: _onGameComplete,
              )
            : _result != null
                ? GameResultView(
                    heroEmoji: '✅',
                    title: _finalScore >= 80 ? 'Wonderful!' : 'Good effort!',
                    score: _finalScore,
                    leveledUp: _leveledUp,
                    infoRows: [
                      GameInfoRowData(
                        icon: Icons.touch_app_rounded,
                        label: 'Total moves',
                        value: '${_result!.moves}',
                      ),
                      GameInfoRowData(
                        icon: Icons.timer_outlined,
                        label: 'Time taken',
                        value: '${_result!.duration.inSeconds}s',
                      ),
                      GameInfoRowData(
                        icon: Icons.grid_view_rounded,
                        label: 'Pairs matched',
                        value: '$_pairs',
                      ),
                      GameInfoRowData(
                        icon: Icons.signal_cellular_alt_rounded,
                        label: 'Level',
                        value: '$_level of 5',
                      ),
                    ],
                    onPlayAgain: () {
                      _recomputeLevel();
                      _startGame();
                    },
                    onExit: () => Navigator.of(context).pop(),
                  )
                : GameIntroView(
                    heroEmoji: '🧠',
                    title: 'Memory Match',
                    description:
                        'Tap two cards to find a matching pair. Take your time — there is no rush.',
                    level: _level,
                    levelLabel:
                        DifficultyOptimizer.instance.levelLabel(_level),
                    levelColorValue: DifficultyOptimizer.instance
                        .levelColorValue(_level),
                    infoRows: [
                      GameInfoRowData(
                        icon: Icons.grid_on_rounded,
                        label: 'Cards',
                        value: '${_pairs * 2}',
                      ),
                    ],
                    onStart: _startGame,
                  ),
      ),
    );
  }
}