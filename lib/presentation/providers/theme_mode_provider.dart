import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';

/// Persisted theme mode: light / dark / system.
///
/// Default is `dark` (the app's premium finance aesthetic). Users can switch
/// to Light or System via the Appearance section of Settings; the choice
/// persists to the `user_prefs` Hive box and is re-loaded on next launch.
/// Widget colors come from `context.palette` (a `ThemeExtension` defined in
/// `core/theme/app_palette.dart`) so switching modes updates every screen
/// uniformly.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(_load());

  static const _prefKey = 'theme_mode';

  static ThemeMode _load() {
    try {
      final box = Hive.box(AppConstants.hiveBoxUserPrefs);
      final raw = box.get(_prefKey) as String?;
      switch (raw) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        case 'system':
          return ThemeMode.system;
      }
    } catch (_) {
      // Box not opened yet — fall through to default.
    }
    return ThemeMode.dark;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      final box = Hive.box(AppConstants.hiveBoxUserPrefs);
      await box.put(_prefKey, mode.name);
    } catch (_) {
      // Best effort — UI already reflects the change.
    }
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController();
});
