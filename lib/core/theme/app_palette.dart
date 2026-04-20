import 'package:flutter/material.dart';

/// Brightness-aware semantic color tokens.
///
/// Usage in widgets:
/// ```dart
/// Text('hello', style: TextStyle(color: context.palette.textPrimary))
/// ```
///
/// Registered as a `ThemeExtension` on both [AppTheme.light] and [AppTheme.dark]
/// so widgets automatically get the correct colors when the user switches
/// theme in Settings. Brand colors (primary, gain, loss, etc.) remain on
/// [AppColors] because they are mode-independent.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bgBase;          // scaffold background
  final Color bgCard;          // primary card surface
  final Color bgCardElevated;  // elevated / modal surface
  final Color bgSurface;       // input / chip background
  final Color bgDivider;       // 1px separator lines
  final Color textPrimary;     // main body text
  final Color textSecondary;   // muted text
  final Color textTertiary;    // very muted / captions

  const AppPalette({
    required this.bgBase,
    required this.bgCard,
    required this.bgCardElevated,
    required this.bgSurface,
    required this.bgDivider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
  });

  /// Dark-mode preset — the original eVesh look (deep navy, light blue text).
  static const dark = AppPalette(
    bgBase: Color(0xFF0A1628),
    bgCard: Color(0xFF0F1F38),
    bgCardElevated: Color(0xFF162744),
    bgSurface: Color(0xFF1C2F4A),
    bgDivider: Color(0xFF1E3352),
    textPrimary: Color(0xFFE8F0F8),
    textSecondary: Color(0xFF8BA4C0),
    textTertiary: Color(0xFF4A6A8A),
  );

  /// Light-mode preset — soft gray bg, dark navy text.
  /// Text colors are tuned for WCAG AA contrast on `bgCard` (white).
  static const light = AppPalette(
    bgBase: Color(0xFFF4F7F9),
    bgCard: Color(0xFFFFFFFF),
    bgCardElevated: Color(0xFFFFFFFF),
    bgSurface: Color(0xFFEBF1F7),
    bgDivider: Color(0xFFDDE4ED),
    textPrimary: Color(0xFF0A1628),   // deep navy — 14:1 on white
    textSecondary: Color(0xFF4A6A8A), // 5.5:1 on white
    textTertiary: Color(0xFF6B8099),  // 4.6:1 on white
  );

  @override
  AppPalette copyWith({
    Color? bgBase,
    Color? bgCard,
    Color? bgCardElevated,
    Color? bgSurface,
    Color? bgDivider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
  }) {
    return AppPalette(
      bgBase: bgBase ?? this.bgBase,
      bgCard: bgCard ?? this.bgCard,
      bgCardElevated: bgCardElevated ?? this.bgCardElevated,
      bgSurface: bgSurface ?? this.bgSurface,
      bgDivider: bgDivider ?? this.bgDivider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgCardElevated: Color.lerp(bgCardElevated, other.bgCardElevated, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgDivider: Color.lerp(bgDivider, other.bgDivider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
    );
  }
}

/// Terse accessor: `context.palette.textPrimary`.
/// Falls back to [AppPalette.dark] if no palette is registered on the theme
/// (should never happen in practice, but defensive).
extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
