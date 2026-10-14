import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/auth/auth_store.dart';
import '../../core/domain/app_models.dart';
import '../../core/games/difficulty_optimizer.dart';
import '../../core/games/game_intro_view.dart';
import '../../core/games/game_result_view.dart';
import '../../core/localization/app_languages.dart';
import '../../core/theme/app_theme.dart';
import 'sequence_recall_game.dart';

class SequenceRecallScreen extends StatefulWidget {
  final SmaranStore store;
  const SequenceRecallScreen({super.key, required this.store});

  @override
  State<SequenceRecallScreen> createState() => _SequenceRecallScreenState();
}

class _SequenceRecallScreenState extends State<SequenceRecallScreen> {
  final _tts = FlutterTts();

  late int _level;
  late int _sequenceLength;
  bool _playing = false;
  SequenceRecallResult? _result;
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
        .recommendedLevel('sequence_recall', widget.store.gameSessions);

    switch (_level) {
      case 1:
        _sequenceLength = 3;
        break;
      case 2:
        _sequenceLength = 4;
        break;
      case 3:
        _sequenceLength = 5;
        break;
      case 4:
        _sequenceLength = 6;
        break;
      default:
        _sequenceLength = 6; // cap — pool has only 9 items
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.setSpeechRate(0.43);
      await _tts.setLanguage(AuthStore.instance.preferredLanguage.localeCode);
      await _tts.speak(text);
    } catch (_) {}
  }

  void _start() {
    setState(() {
      _playing = true;
      _result = null;
      _leveledUp = false;
    });
    _speak('Watch the order carefully.');
  }

  Future<void> _onComplete(SequenceRecallResult r) async {
    // If the game says "correct", userPicks.length always equals
    // sequence.length (see _finish(true) in the game). So the old
    // penalty formula always evaluated to 100. Keep it simple:
    _finalScore = r.correct ? 100 : 40;

    final oldLevel = _level;

    widget.store.gameSessions.add(GameSession(
      gameId: 'sequence_recall',
      score: _finalScore,
      durationSec: r.duration.inSeconds,
      difficulty: _level,
      moves: r.userPicks.length,
      timestamp: DateTime.now(),
    ));
    await widget.store.save();

    final newLevel = DifficultyOptimizer.instance
        .recommendedLevel('sequence_recall', widget.store.gameSessions);
    _leveledUp = newLevel > oldLevel;

    if (!mounted) return;
    setState(() {
      _playing = false;
      _result = r;
    });

    await _speak(r.correct
        ? 'Wonderful! You remembered the order.'
        : 'Good try. Let\'s practice again.');
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
          'Sequence Recall',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cDeep),
        ),
      ),
      body: SafeArea(
        child: _playing
            ? SequenceRecallGame(
                sequenceLength: _sequenceLength,
                difficulty: _level,
                onComplete: _onComplete,
              )
            : _result != null
                ? GameResultView(
                    heroEmoji: '🧩',
                    title: _finalScore >= 80 ? 'Wonderful!' : 'Good try!',
                    score: _finalScore,
                    leveledUp: _leveledUp,
                    infoRows: [
                      GameInfoRowData(
                        icon: Icons.format_list_numbered_rounded,
                        label: 'Sequence length',
                        value: '$_sequenceLength',
                      ),
                      GameInfoRowData(
                        icon: Icons.timer_outlined,
                        label: 'Time taken',
                        value: '${_result!.duration.inSeconds}s',
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
                    heroEmoji: '🧩',
                    title: 'Sequence Recall',
                    description:
                        'Watch the order of pictures, then tap them in the same order.',
                    level: _level,
                    levelLabel:
                        DifficultyOptimizer.instance.levelLabel(_level),
                    levelColorValue:
                        DifficultyOptimizer.instance.levelColorValue(_level),
                    infoRows: [
                      GameInfoRowData(
                        icon: Icons.format_list_numbered_rounded,
                        label: 'Items to remember',
                        value: '$_sequenceLength',
                      ),
                    ],
                    onStart: _start,
                  ),
      ),
    );
  }
}