import 'package:flutter/material.dart';

import '../../core/auth/auth_store.dart';
import '../../core/localization/app_languages.dart';
import '../../core/theme/app_theme.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends State<LanguageSelectionScreen> {
  AppLanguage? _selected;

  Future<void> _continue() async {
    if (_selected == null) return;
    await AuthStore.instance.setLanguage(_selected!);
    // PreHomeRouter detects hasChosenLanguage and rebuilds.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Center(child: Logo(size: 72)),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Smaran',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: cDeep,
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Choose your language',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: cMuted),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.6,
                ),
                itemCount: AppLanguage.values.length,
                itemBuilder: (_, i) {
                  final lang = AppLanguage.values[i];
                  final selected = _selected == lang;
                  return _LangCard(
                    lang: lang,
                    selected: selected,
                    onTap: () => setState(() => _selected = lang),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: primaryButton(
                'Continue',
                _selected == null ? null : _continue,
                icon: Icons.arrow_forward_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangCard extends StatelessWidget {
  final AppLanguage lang;
  final bool selected;
  final VoidCallback onTap;

  const _LangCard({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? cSoft : cWhite,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? cPrimaryDark : cBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: lang.accentColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  lang.englishName[0],
                  style: const TextStyle(
                    color: cPrimaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.nativeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: cText,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      lang.englishName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: cMuted,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: cPrimaryDark,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}