import 'package:flutter/material.dart';

import '../../core/domain/app_models.dart';
import '../../core/theme/app_theme.dart';
import 'memory_match_screen.dart';
import 'pattern_tap_screen.dart';
import 'sequence_recall_screen.dart';
import 'sound_match_screen.dart';
import 'word_picture_screen.dart';

class _GameInfo {
  final String id;
  final String title;
  final String tagline;
  final String skill;
  final IconData icon;
  final Color accent;
  const _GameInfo({
    required this.id,
    required this.title,
    required this.tagline,
    required this.skill,
    required this.icon,
    required this.accent,
  });
}

const _games = <_GameInfo>[
  _GameInfo(
    id: 'memory_match',
    title: 'Memory Match',
    tagline: 'Find the matching pairs',
    skill: 'Recall',
    icon: Icons.grid_view_rounded,
    accent: Color(0xFFE5F0D8),
  ),
  _GameInfo(
    id: 'sequence_recall',
    title: 'Sequence Recall',
    tagline: 'Remember the order',
    skill: 'Working memory',
    icon: Icons.format_list_numbered_rounded,
    accent: Color(0xFFF5E6C7),
  ),
  _GameInfo(
    id: 'pattern_tap',
    title: 'Pattern Tap',
    tagline: 'Spot the visual pattern',
    skill: 'Attention',
    icon: Icons.auto_awesome_rounded,
    accent: Color(0xFFDCECF2),
  ),
  _GameInfo(
    id: 'word_picture',
    title: 'Word & Picture',
    tagline: 'Match words to images',
    skill: 'Semantic memory',
    icon: Icons.image_search_rounded,
    accent: Color(0xFFF6DCDD),
  ),
  _GameInfo(
    id: 'sound_match',
    title: 'Sound Match',
    tagline: 'Listen and match sounds',
    skill: 'Sensory recall',
    icon: Icons.music_note_rounded,
    accent: Color(0xFFECE6F1),
  ),
];

class GamesHubScreen extends StatefulWidget {
  final SmaranStore store;
  const GamesHubScreen({super.key, required this.store});

  @override
  State<GamesHubScreen> createState() => _GamesHubScreenState();
}

class _GamesHubScreenState extends State<GamesHubScreen> {
  int _completedToday() {
    final today = DateTime.now();
    final ids = <String>{};
    for (final s in widget.store.gameSessions) {
      if (s.timestamp.year == today.year &&
          s.timestamp.month == today.month &&
          s.timestamp.day == today.day) {
        ids.add(s.gameId);
      }
    }
    return ids.length;
  }

  Future<void> _openGame(_GameInfo game) async {
    Widget? screen;
    switch (game.id) {
      case 'memory_match':
        screen = MemoryMatchScreen(store: widget.store);
        break;
      case 'sequence_recall':
        screen = SequenceRecallScreen(store: widget.store);
        break;
      case 'pattern_tap':
        screen = PatternTapScreen(store: widget.store);
        break;
      case 'word_picture':
        screen = WordPictureScreen(store: widget.store);
        break;
      case 'sound_match':
        screen = SoundMatchScreen(store: widget.store);
        break;
    }

    if (screen == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen!),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final completed = _completedToday();
    final total = _games.length;

    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cBg,
        elevation: 0,
        title: const Text(
          'Cognitive Games',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: cDeep,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cDeep,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: cSoft,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today: $completed / $total activities',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Calm, simple practice. No pressure.',
                            style: TextStyle(
                              color: Color(0xFFD8E9DE),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'CHOOSE AN ACTIVITY',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w900,
                  color: cPrimaryDark,
                ),
              ),
              const SizedBox(height: 10),
              ..._games.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: _GameCard(game: g, onTap: () => _openGame(g)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final _GameInfo game;
  final VoidCallback onTap;

  const _GameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cWhite,
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      shadowColor: const Color(0x1A7A694E),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: game.accent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  game.icon,
                  size: 28,
                  color: cPrimaryDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: cText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.tagline,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: cMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: cSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            game.skill,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: cPrimaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.play_circle_fill_rounded,
                size: 34,
                color: cPrimaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}