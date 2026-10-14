import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Result returned when a Memory Match game completes.
class MemoryGameResult {
  final int moves;
  final int pairs;
  final Duration duration;
  const MemoryGameResult({
    required this.moves,
    required this.pairs,
    required this.duration,
  });
}

/// The game board for Memory Match.
///
/// This widget only handles:
///   - Rendering the grid of cards
///   - Flip / match / mismatch logic
///   - Reporting the result via [onComplete]
///
/// It does NOT handle difficulty, TTS, or persistence. Those are the
/// responsibility of the parent screen (MemoryMatchScreen).
class MemoryMatchGame extends StatefulWidget {
  final int pairs;
  final int difficulty;
  final void Function(MemoryGameResult) onComplete;

  const MemoryMatchGame({
    super.key,
    required this.pairs,
    required this.difficulty,
    required this.onComplete,
  });

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> {
  static const _emojis = [
    '🌸', '🐦', '🏠', '🌳', '⭐', '🎵',
    '🍎', '☀️', '🌙', '🌈', '☕', '🐝',
  ];

  late List<_CardData> _cards;
  int? _firstIndex;
  bool _locked = false;
  int _moves = 0;
  int _matched = 0;
  late DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _setupDeck();
  }

  void _setupDeck() {
    final deck = <String>[];
    for (int i = 0; i < widget.pairs; i++) {
      final e = _emojis[i % _emojis.length];
      deck.add(e);
      deck.add(e);
    }
    deck.shuffle();

    _cards = List.generate(
      deck.length,
      (i) => _CardData(value: deck[i]),
    );
    _startedAt = DateTime.now();
  }

  /// Number of grid columns — grows gently so cards stay large and tappable.
  int _columns() {
    final total = widget.pairs * 2;
    if (total <= 6) return 3;   // 6 cards
    if (total <= 8) return 4;   // 8 cards
    if (total <= 12) return 4;  // 12 cards
    if (total <= 16) return 4;  // 16 cards
    return 5;                    // 20 cards
  }

  Future<void> _handleTap(int index) async {
    if (_locked) return;
    final card = _cards[index];
    if (card.flipped || card.matched) return;

    setState(() => card.flipped = true);

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    _moves++;

    final first = _cards[_firstIndex!];
    if (first.value == card.value) {
      // Match
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        first.matched = true;
        card.matched = true;
        _firstIndex = null;
        _matched++;
      });

      if (_matched == widget.pairs) {
        final dur = DateTime.now().difference(_startedAt);
        widget.onComplete(MemoryGameResult(
          moves: _moves,
          pairs: widget.pairs,
          duration: dur,
        ));
      }
    } else {
      // Mismatch — flip back after a short pause
      _locked = true;
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        first.flipped = false;
        card.flipped = false;
        _firstIndex = null;
        _locked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cols = _columns();
    final total = _cards.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              _StatPill(
                icon: Icons.touch_app_rounded,
                label: 'Moves',
                value: '$_moves',
              ),
              const SizedBox(width: 10),
              _StatPill(
                icon: Icons.check_circle_rounded,
                label: 'Matched',
                value: '$_matched / ${widget.pairs}',
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: total,
              itemBuilder: (_, i) {
                final card = _cards[i];
                return _FlipCard(
                  data: card,
                  onTap: () => _handleTap(i),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _CardData {
  final String value;
  bool flipped = false;
  bool matched = false;
  _CardData({required this.value});
}

class _FlipCard extends StatelessWidget {
  final _CardData data;
  final VoidCallback onTap;

  const _FlipCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final show = data.flipped || data.matched;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.7, end: 1.0).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: show ? _faceUp(data.matched, data.value) : _faceDown(),
      ),
    );
  }

  Widget _faceDown() => Container(
        key: const ValueKey('down'),
        decoration: BoxDecoration(
          color: cDeep,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A7A694E),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.question_mark_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      );

  Widget _faceUp(bool matched, String value) => Container(
        key: ValueKey('up-$value-$matched'),
        decoration: BoxDecoration(
          color: matched ? const Color(0xFFB8DE9C) : cSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: matched ? cPrimaryDark : Colors.transparent,
            width: matched ? 2 : 0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A7A694E),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(value, style: const TextStyle(fontSize: 40)),
      );
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: cPrimaryDark),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cMuted,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: cText,
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