import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Result returned when a Pattern Tap game completes.
class PatternTapResult {
  final int correctCount;
  final int totalRounds;
  final Duration duration;

  const PatternTapResult({
    required this.correctCount,
    required this.totalRounds,
    required this.duration,
  });
}

/// The game board for Pattern Tap.
///
/// Shows a grid where one item is subtly different. Player taps the odd one.
/// Runs [totalRounds] rounds, then reports a [PatternTapResult].
class PatternTapGame extends StatefulWidget {
  final int gridSize;
  final int totalRounds;
  final int difficulty;
  final void Function(PatternTapResult) onComplete;

  const PatternTapGame({
    super.key,
    required this.gridSize,
    required this.totalRounds,
    required this.difficulty,
    required this.onComplete,
  });

  @override
  State<PatternTapGame> createState() => _PatternTapGameState();
}

class _PatternTapGameState extends State<PatternTapGame> {
  /// Visually similar pairs — the game is a genuine "spot the odd one,"
  /// not a "spot a completely different object."
  static const List<(String, String)> _pairs = [
    ('🍎', '🍏'), // red apple vs green apple
    ('🌸', '🌺'), // cherry blossom vs hibiscus
    ('🏠', '🏡'), // house vs house with garden
    ('🎵', '🎶'), // single note vs notes
    ('🌳', '🌲'), // deciduous vs evergreen
    ('🐟', '🐠'), // fish vs tropical fish
    ('🌙', '🌛'), // crescent moon vs moon face
    ('🌻', '🌼'), // sunflower vs daisy
    ('☕', '🫖'), // coffee vs teapot
    ('🐦', '🦅'), // small bird vs eagle
  ];

  final Random _rng = Random();

  late int _correctIndex;
  late List<String> _grid;
  int _roundsPlayed = 0;
  int _correctCount = 0;
  bool _locked = false;
  late DateTime _startedAt;

  /// Which tile the user tapped in the current round (for feedback).
  /// Null means "no tap yet this round."
  int? _tappedIndex;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _buildNextRound(); // pure mutation — safe from initState
  }

  int get _crossAxisCount {
    if (widget.gridSize <= 4) return 2;
    if (widget.gridSize <= 9) return 3;
    return 4;
  }

  /// Pure state mutation. Does NOT call setState, so it's safe from
  /// initState and from inside setState callbacks.
  void _buildNextRound() {
    final pair = _pairs[_rng.nextInt(_pairs.length)];
    _correctIndex = _rng.nextInt(widget.gridSize);
    _grid = List.generate(
      widget.gridSize,
      (i) => i == _correctIndex ? pair.$2 : pair.$1,
    );
    _locked = false;
    _tappedIndex = null;
  }

  void _nextRound() {
    setState(_buildNextRound);
  }

  void _tap(int index) {
    if (_locked) return;

    setState(() {
      _locked = true;
      _tappedIndex = index;
    });

    final correct = index == _correctIndex;
    if (correct) _correctCount++;

    // Brief feedback delay so the user sees which tile was correct
    // (or which they got wrong) before the next round appears.
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      _roundsPlayed++;
      if (_roundsPlayed >= widget.totalRounds) {
        final dur = DateTime.now().difference(_startedAt);
        widget.onComplete(PatternTapResult(
          correctCount: _correctCount,
          totalRounds: widget.totalRounds,
          duration: dur,
        ));
      } else {
        _nextRound();
      }
    });
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
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: cDeep,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap the different one',
            style: TextStyle(fontSize: 15, color: cMuted),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: _crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: List.generate(widget.gridSize, (i) {
                final tapped = _tappedIndex != null;
                final isCorrectTile = i == _correctIndex;
                final isTappedTile = _tappedIndex == i;

                // Default look
                Color bg = cWhite;
                Color border = cBorder;
                double borderWidth = 1.5;

                // Feedback state: highlight correct tile green,
                // wrong tap red (only after the user has tapped).
                if (tapped) {
                  if (isCorrectTile) {
                    bg = const Color(0xFFE4F1D8);
                    border = const Color(0xFF7BB662);
                    borderWidth = 2.5;
                  } else if (isTappedTile) {
                    bg = const Color(0xFFF6DCDD);
                    border = const Color(0xFFD98A8A);
                    borderWidth = 2.5;
                  }
                }

                return Semantics(
                  label: 'Tile ${i + 1} of ${widget.gridSize}',
                  button: true,
                  child: InkWell(
                    onTap: () => _tap(i),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: border, width: borderWidth),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _grid[i],
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}