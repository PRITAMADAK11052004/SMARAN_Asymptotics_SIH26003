import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared intro screen used by every cognitive game.
class GameIntroView extends StatelessWidget {
  final String heroEmoji;
  final String title;
  final String description;
  final int level;
  final String levelLabel;
  final int levelColorValue;
  final List<GameInfoRowData> infoRows;
  final VoidCallback onStart;

  const GameIntroView({
    super.key,
    required this.heroEmoji,
    required this.title,
    required this.description,
    required this.level,
    required this.levelLabel,
    required this.levelColorValue,
    required this.onStart,
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
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: cDeep,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.5, color: cMuted),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Color(levelColorValue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Level $level · $levelLabel',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: cPrimaryDark,
                ),
              ),
            ),
          ),
          if (infoRows.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cWhite,
                borderRadius: BorderRadius.circular(16),
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
          primaryButton('Start Game', onStart, icon: Icons.play_arrow_rounded),
        ],
      ),
    );
  }
}

class GameInfoRowData {
  final IconData icon;
  final String label;
  final String value;
  const GameInfoRowData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class GameInfoRow extends StatelessWidget {
  final GameInfoRowData data;
  const GameInfoRow({super.key, required this.data});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(data.icon, color: cPrimaryDark, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              data.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cText,
              ),
            ),
          ),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: cPrimaryDark,
            ),
          ),
        ],
      );
}