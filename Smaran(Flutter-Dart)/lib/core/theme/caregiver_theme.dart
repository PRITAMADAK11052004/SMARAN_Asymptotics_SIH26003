import 'package:flutter/material.dart';

/// Smaran v2 — Caregiver design tokens (matches target mockup)
class CG {
  // Backgrounds
  static const bg = Color(0xFFFFFBE8);        // warm beige
  static const card = Colors.white;
  static const cardSoft = Color(0xFFF5F1E3);

  // Primary green family
  static const primary = Color(0xFF1B4D32);   // deep forest
  static const primaryMid = Color(0xFF2D6A4F);
  static const primarySoft = Color(0xFFDCEFDC);
  static const primaryPale = Color(0xFFEBF5EB);

  // Stat tile accents
  static const gamesBg = Color(0xFFDCEFDC);
  static const gamesFg = Color(0xFF2D6A4F);
  static const medicineBg = Color(0xFFDDEBFA);
  static const medicineFg = Color(0xFF3F72AF);
  static const hydrationBg = Color(0xFFD9F0EC);
  static const hydrationFg = Color(0xFF2E8B7A);
  static const moodBg = Color(0xFFFADCDC);
  static const moodFg = Color(0xFFC64A4A);

  // Semantic
  static const success = Color(0xFF4F9A42);
  static const warning = Color(0xFFE49A1E);
  static const danger  = Color(0xFFC64A4A);
  static const info    = Color(0xFF4A90D9);
  static const purple  = Color(0xFF8A5CBF);

  // Text
  static const textPrimary = Color(0xFF1B1B1B);
  static const textMuted   = Color(0xFF6B7568);
  static const textFaint   = Color(0xFF9AA39C);

  // Borders
  static const border       = Color(0xFFEDE7D6);
  static const borderStrong = Color(0xFFE0D9C4);

  // Radii
  static const rCard   = 20.0;
  static const rChip   = 12.0;
  static const rButton = 14.0;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];
}