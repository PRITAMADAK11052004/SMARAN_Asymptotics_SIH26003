import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Result returned when a Sound Match game completes.
class SoundMatchResult {
  final int correctCount;
  final int totalRounds;
  final Duration duration;

  const SoundMatchResult({
    required this.correctCount,
    required this.totalRounds,
    required this.duration,
  });
}

/// The game board for Sound Match.
///
/// The parent screen handles the TTS side. This widget only shows the grid
/// and reports taps. The current target word is exposed via [targetWord] so
/// the parent can speak it.
class SoundMatchGame extends StatefulWidget {
  final int optionsCount;
  final int totalRounds;
  final int difficulty;
  final void Function(SoundMatchResult) onComplete;
  final void Function(String word) onSpeak;
  final VoidCallback onRoundStart;

  const SoundMatchGame({
    super.key,
    required this.optionsCount,
    required this.totalRounds,
    required this.difficulty,
    required this.onComplete,
    required this.onSpeak,
    required this.onRoundStart,
  });

  @override
  State<SoundMatchGame> createState() => SoundMatchGameState();
}

/// Public state class so the parent screen can read [targetWord] via a
/// GlobalKey. Do not rename to _SoundMatchGameState.
class SoundMatchGameState extends State<SoundMatchGame> {
  static const _items = [
    ('Elephant', '🐘'),
    ('Flower', '🌸'),
    ('House', '🏠'),
    ('Sun', '☀️'),
    ('Tree', '🌳'),
    ('Tea', '🫖'),
    ('Music', '🎵'),
    ('Bird', '🐦'),
    ('Fish', '🐟'),
    ('Book', '📖'),
    ('Rhino', '🦏'),
    ('Moon', '🌙'),
  ];

  late (String, String) _target;
  late List<(String, String)> _options;
  int _roundsPlayed = 0;
  int _correctCount = 0;
  bool _locked = false;
  late DateTime _startedAt;

  /// The word the user needs to match this round.
  String get targetWord => _target.$1;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _nextRound();
  }

  void _nextRound() {
    final pool = [..._items]..shuffle();
    _target = pool.first;
    _options = pool.take(widget.optionsCount).toList()..shuffle();
    setState(() => _locked = false);
    widget.onRoundStart();
  }

  void _tap((String, String) option) {
    if (_locked) return;
    setState(() => _locked = true);

    final correct = option.$1 == _target.$1;
    if (correct) _correctCount++;
    widget.onSpeak(correct ? 'Yes!' : 'Not that one');
    _roundsPlayed++;

    if (_roundsPlayed >= widget.totalRounds) {
      final dur = DateTime.now().difference(_startedAt);
      widget.onComplete(SoundMatchResult(
        correctCount: _correctCount,
        totalRounds: widget.totalRounds,
        duration: dur,
      ));
    } else {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) _nextRound();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: [
          Text(
            'Round ${_roundsPlayed + 1} of ${widget.totalRounds}',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, color: cDeep),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 140,
            height: 140,
            child: Material(
              color: cPrimaryDark,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () => widget.onSpeak(_target.$1),
                customBorder: const CircleBorder(),
                child: const Icon(Icons.volume_up_rounded,
                    size: 66, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Tap to hear again',
              style: TextStyle(fontSize: 15, color: cMuted)),
          const Spacer(),
          const Text('Which picture matches the sound?',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: cText)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _options.map((o) {
              return InkWell(
                onTap: () => _tap(o),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: cWhite,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: cBorder, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(o.$2, style: const TextStyle(fontSize: 52)),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}