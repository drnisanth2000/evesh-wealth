import 'package:flutter/material.dart';

/// eVesh brand color palette
abstract class AppColors {
  // ─── Primary brand ─────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1B8A5A);        // eVesh green
  static const Color primaryLight = Color(0xFF2DBF7E);
  static const Color primaryDark = Color(0xFF145E3D);
  static const Color primaryMuted = Color(0xFF1B8A5A26); // 15% opacity

  // ─── Background (dark theme) ───────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0A1628);         // deep navy
  static const Color bgCard = Color(0xFF0F1F38);         // card surface
  static const Color bgCardElevated = Color(0xFF162744); // elevated card
  static const Color bgSurface = Color(0xFF1C2F4A);      // input / chip bg
  static const Color bgDivider = Color(0xFF1E3352);

  // ─── Background (light theme) ─────────────────────────────────────────────
  static const Color bgLight = Color(0xFFF4F7F9);
  static const Color bgCardLight = Color(0xFFFFFFFF);
  static const Color bgSurfaceLight = Color(0xFFEBF1F7);

  // ─── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFE8F0F8);     // main text (dark mode)
  static const Color textSecondary = Color(0xFF8BA4C0);   // muted text
  static const Color textTertiary = Color(0xFF4A6A8A);    // very muted
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0A1628); // main text (light mode)
  static const Color textSecondaryLight = Color(0xFF4A6A8A);

  // ─── Semantic ─────────────────────────────────────────────────────────────
  static const Color gain = Color(0xFF22C55E);    // profit / positive
  static const Color loss = Color(0xFFEF4444);    // loss / negative
  static const Color warning = Color(0xFFF59E0B); // amber / warning
  static const Color info = Color(0xFF3B82F6);    // blue / informational (same as chartColors[1])

  // ─── Alert severity ───────────────────────────────────────────────────────
  static const Color alertUrgent = Color(0xFFEF4444);
  static const Color alertMedium = Color(0xFFF59E0B);
  static const Color alertLow = Color(0xFF22C55E);

  static const Color alertUrgentBg = Color(0x1AEF4444);  // 10% opacity
  static const Color alertMediumBg = Color(0x1AF59E0B);
  static const Color alertLowBg = Color(0x1A22C55E);

  // ─── Chart palette (8 distinct colors for member/asset charts) ────────────
  static const List<Color> chartColors = [
    Color(0xFF1B8A5A), // green (primary)
    Color(0xFF3B82F6), // blue
    Color(0xFFF59E0B), // amber
    Color(0xFFEC4899), // pink
    Color(0xFF8B5CF6), // violet
    Color(0xFF06B6D4), // cyan
    Color(0xFFFF6B35), // orange
    Color(0xFF84CC16), // lime
  ];

  // ─── Asset class colors (for allocation pie chart) ────────────────────────
  static const Map<String, Color> assetClassColors = {
    'Core Equity': Color(0xFF1B8A5A),
    'Satellite Equity': Color(0xFF2DBF7E),
    'Hybrid': Color(0xFF3B82F6),
    'Debt': Color(0xFF8B5CF6),
    'Liquid': Color(0xFF06B6D4),
    'Gold': Color(0xFFF59E0B),
    'Alternate': Color(0xFFFF6B35),
  };

  // ─── Goal status colors ───────────────────────────────────────────────────
  static const Color goalAchieved = Color(0xFF22C55E);
  static const Color goalOnTrack = Color(0xFF3B82F6);
  static const Color goalWatch = Color(0xFFF59E0B);
  static const Color goalBehind = Color(0xFFEF4444);

  // ─── Bucket colors ────────────────────────────────────────────────────────
  static const Color bucket1 = Color(0xFF3B82F6);  // Stability — blue
  static const Color bucket2 = Color(0xFF8B5CF6);  // Income — violet
  static const Color bucket3 = Color(0xFF1B8A5A);  // Growth — green
}
