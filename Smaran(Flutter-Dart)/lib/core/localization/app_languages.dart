import 'package:flutter/material.dart';

enum AppLanguage {
  assamese,
  bengali,
  bodo,
  english,
  garo,
  hindi,
  khasi,
  kokborok,
  meitei,
  mizo,
  nagamese,
  nepali,
}

extension AppLanguageX on AppLanguage {
  String get key => name;

  String get englishName => switch (this) {
        AppLanguage.assamese => 'Assamese',
        AppLanguage.bengali => 'Bengali',
        AppLanguage.bodo => 'Bodo',
        AppLanguage.english => 'English',
        AppLanguage.garo => 'Garo',
        AppLanguage.hindi => 'Hindi',
        AppLanguage.khasi => 'Khasi',
        AppLanguage.kokborok => 'Kokborok',
        AppLanguage.meitei => 'Meitei (Manipuri)',
        AppLanguage.mizo => 'Mizo',
        AppLanguage.nagamese => 'Nagamese',
        AppLanguage.nepali => 'Nepali',
      };

  String get nativeName => switch (this) {
        AppLanguage.assamese => 'অসমীয়া',
        AppLanguage.bengali => 'বাংলা',
        AppLanguage.bodo => 'बड़ो',
        AppLanguage.english => 'English',
        AppLanguage.garo => 'A·chik',
        AppLanguage.hindi => 'हिन्दी',
        AppLanguage.khasi => 'Khasi',
        AppLanguage.kokborok => 'Kokborok',
        AppLanguage.meitei => 'মৈতৈলোন্',
        AppLanguage.mizo => 'Mizo ṭawng',
        AppLanguage.nagamese => 'Nagamese',
        AppLanguage.nepali => 'नेपाली',
      };

  String get localeCode => switch (this) {
        AppLanguage.assamese => 'as-IN',
        AppLanguage.bengali => 'bn-IN',
        AppLanguage.bodo => 'brx-IN',
        AppLanguage.english => 'en-IN',
        AppLanguage.garo => 'grt-IN',
        AppLanguage.hindi => 'hi-IN',
        AppLanguage.khasi => 'kha-IN',
        AppLanguage.kokborok => 'trp-IN',
        AppLanguage.meitei => 'mni-IN',
        AppLanguage.mizo => 'lus-IN',
        AppLanguage.nagamese => 'nag-IN',
        AppLanguage.nepali => 'ne-NP',
      };

  Color get accentColor => switch (this) {
        AppLanguage.assamese => const Color(0xFFE8D5B7),
        AppLanguage.bengali => const Color(0xFFF1DCE0),
        AppLanguage.bodo => const Color(0xFFDDECF2),
        AppLanguage.english => const Color(0xFFE5F0D8),
        AppLanguage.garo => const Color(0xFFF5E6C7),
        AppLanguage.hindi => const Color(0xFFF6DCDD),
        AppLanguage.khasi => const Color(0xFFDCE9D1),
        AppLanguage.kokborok => const Color(0xFFF8E7BF),
        AppLanguage.meitei => const Color(0xFFECE6F1),
        AppLanguage.mizo => const Color(0xFFE4EEF1),
        AppLanguage.nagamese => const Color(0xFFF7DDD2),
        AppLanguage.nepali => const Color(0xFFE5F0D8),
      };
}

AppLanguage parseLanguage(String? raw) {
  if (raw == null) return AppLanguage.english;
  for (final lang in AppLanguage.values) {
    if (lang.key == raw) return lang;
  }
  return AppLanguage.english;
}