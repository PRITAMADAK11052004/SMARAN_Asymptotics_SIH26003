import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Result returned when a Word & Picture game completes.
class WordPictureResult {
  final int correctCount;
  final int totalRounds;
  final Duration duration;

  const WordPictureResult({
    required this.correctCount,
    required this.totalRounds,
    required this.duration,
  });
}

/// The game board for Word & Picture.
class WordPictureGame extends StatefulWidget {
  final int optionsCount;
  final int totalRounds;
  final int difficulty;
  final void Function(WordPictureResult) onComplete;

  const WordPictureGame({
    super.key,
    required this.optionsCount,
    required this.totalRounds,
    required this.difficulty,
    required this.onComplete,
  });

  @override
  State<WordPictureGame> createState() => _WordPictureGameState();
}

class _WordPictureGameState extends State<WordPictureGame> {
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
  }

  void _tap((String, String) option) {
    if (_locked) return;
    setState(() => _locked = true);

    final correct = option.$1 == _target.$1;
    if (correct) _correctCount++;
    _roundsPlayed++;

    if (_roundsPlayed >= widget.totalRounds) {
      final dur = DateTime.now().difference(_startedAt);
      widget.onComplete(WordPictureResult(
        correctCount: _correctCount,
        totalRounds: widget.totalRounds,
        duration: dur,
      ));
    } else {
      _nextRound();
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            decoration: BoxDecoration(
              color: cDeep,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              _target.$1,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Tap the matching picture',
              style: TextStyle(fontSize: 15, color: cMuted)),
          const Spacer(),
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