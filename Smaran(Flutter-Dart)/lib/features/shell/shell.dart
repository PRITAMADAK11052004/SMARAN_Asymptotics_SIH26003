import 'package:flutter/material.dart';

import '../../core/domain/app_models.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../games/games_hub_screen.dart';
import '../home/home_screen.dart';
import '../relax/music_screen.dart';
import '../reminders/reminder_screen.dart';
import '../talk/talking_screen.dart';

class Shell extends StatefulWidget {
  final SmaranStore store;
  const Shell({super.key, required this.store});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tabIndex = 0;

  void _navigate(String route) {
    switch (route) {
      case 'home':
        setState(() => _tabIndex = 0);
        break;
      case 'family':
        setState(() => _tabIndex = 1);
        break;
      case 'photos':
        setState(() => _tabIndex = 2);
        break;
      case 'music':
        setState(() => _tabIndex = 3);
        break;
      case 'relax':
        setState(() => _tabIndex = 4);
        break;
    }
  }

  void _openFeature(String route) {
    // Each feature screen owns its own AppBar. Do NOT wrap them.
    Widget? page;
    switch (route) {
      case 'games':
        page = GamesHubScreen(store: widget.store);
        break;
      case 'talk':
        page = const TalkingScreen();
        break;
      case 'reminders':
        page = RemindersScreen(store: widget.store);
        break;
    }
    if (page == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page!),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        store: widget.store,
        onNavigate: _navigate,
        onOpenFeature: _openFeature,
      ),
      const _Placeholder(title: 'Family'),
      const _Placeholder(title: 'Photos'),
      const MusicScreen(),
      const _Placeholder(title: 'Relax'),
    ];

    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _tabIndex, children: pages),
      ),
      bottomNavigationBar: _BottomNav(
        index: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder({required this.title});

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          '$title screen — coming soon.',
          style: const TextStyle(
            fontSize: 18,
            color: cMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.index, required this.onTap});

  List<(String, IconData)> _buildItems() {
    final l = L.current;
    return [
      (l.home, Icons.home_rounded),
      (l.family, Icons.people_alt_rounded),
      (l.photos, Icons.photo_library_rounded),
      (l.music, Icons.music_note_rounded),
      (l.relax, Icons.water_drop_rounded),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    return SafeArea(
      top: false,
      child: Container(
        color: cBg,
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: cWhite,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cBorder, width: 1.1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A7A694E),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final selected = index == i;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 26,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFF3E8CF)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          item.$2,
                          size: 20,
                          color: selected
                              ? cPrimaryDark
                              : const Color(0xFF7E827B),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item.$1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w900
                              : FontWeight.w700,
                          color: selected ? cText : cMuted,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}