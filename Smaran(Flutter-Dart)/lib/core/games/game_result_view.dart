import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'game_intro_view.dart' show GameInfoRow, GameInfoRowData;

/// Shared result screen used by every cognitive game.
class GameResultView extends StatelessWidget {
  final String heroEmoji;
  final String title; // e.g. "Wonderful!" / "Good effort!"
  final int score;
  final bool leveledUp;
  final List<GameInfoRowData> infoRows;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const GameResultView({
    super.key,
    required this.heroEmoji,
    required this.title,
    required this.score,
    required this.onPlayAgain,
    required this.onExit,
    this.leveledUp = false,
    this.infoRows = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Center(child: Text(heroEmoji, style: const TextStyle(fontSize: 88))),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: cDeep,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Score: $score / 100',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: cPrimaryDark,
            ),
          ),
          if (leveledUp) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE4F1D8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '🎉 Ready for the next level!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: cPrimaryDark,
                ),
              ),
            ),
          ],
          if (infoRows.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cBorder),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < infoRows.length; i++) ...[
                    if (i > 0) const Divider(height: 20),
                    GameInfoRow(data: infoRows[i]),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          primaryButton('Play Again', onPlayAgain, icon: Icons.refresh_rounded),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: onExit,
              style: OutlinedButton.styleFrom(
                foregroundColor: cPrimaryDark,
                side: const BorderSide(color: cPrimaryDark, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Back to Games',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}