import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Result returned when a Sequence Recall game completes.
class SequenceRecallResult {
  final List<String> sequence;
  final List<String> userPicks;
  final bool correct;
  final Duration duration;

  const SequenceRecallResult({
    required this.sequence,
    required this.userPicks,
    required this.correct,
    required this.duration,
  });
}

/// The game board for Sequence Recall.
///
/// Shows a sequence of emojis, hides them, then lets the user tap the
/// options in the same order. Reports a [SequenceRecallResult] when done.
class SequenceRecallGame extends StatefulWidget {
  final int sequenceLength;
  final int difficulty;
  final void Function(SequenceRecallResult) onComplete;

  const SequenceRecallGame({
    super.key,
    required this.sequenceLength,
    required this.difficulty,
    required this.onComplete,
  });

  @override
  State<SequenceRecallGame> createState() => _SequenceRecallGameState();
}

enum _Phase { showing, tapping }

class _SequenceRecallGameState extends State<SequenceRecallGame> {
  static const _items = ['🍎', '🌳', '🐘', '🏠', '🌸', '🦏', '🫖', '🎵', '☀️'];

  _Phase _phase = _Phase.showing;
  late List<String> _sequence;
  late List<String> _options;
  final List<String> _userPicks = [];
  late DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    final pool = [..._items]..shuffle();
    _sequence = pool.take(widget.sequenceLength).toList();
    _options = ([..._sequence, ...pool.skip(widget.sequenceLength).take(6)]..shuffle());
    Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() => _phase = _Phase.tapping);
    });
  }

  void _pick(String emoji) {
    if (_phase != _Phase.tapping) return;

    setState(() => _userPicks.add(emoji));

    final idx = _userPicks.length - 1;
    if (_userPicks[idx] != _sequence[idx]) {
      _finish(correct: false);
      return;
    }

    if (_userPicks.length == _sequence.length) {
      _finish(correct: true);
    }
  }

  void _finish({required bool correct}) {
    final dur = DateTime.now().difference(_startedAt);
    widget.onComplete(SequenceRecallResult(
      sequence: _sequence,
      userPicks: List.unmodifiable(_userPicks),
      correct: correct,
      duration: dur,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.showing) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            const Text(
              'Watch the order',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: cDeep,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: _sequence
                  .map((e) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: cSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(e, style: const TextStyle(fontSize: 44)),
                      ))
                  .toList(),
            ),
            const Spacer(),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            'Tap in the same order  ·  ${_userPicks.length} / ${_sequence.length}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: cDeep,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _sequence.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: i < _userPicks.length ? cPrimaryDark : cSoft,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const Spacer(),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: _options
                .map((e) => InkWell(
                      onTap: () => _pick(e),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cBorder, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(e, style: const TextStyle(fontSize: 44)),
                      ),
                    ))
                .toList(),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}