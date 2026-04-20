import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_mode_provider.dart';
import 'presentation/router/app_router.dart';

class EVeshApp extends ConsumerWidget {
  const EVeshApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'eVesh Wealth Manager',
      debugShowCheckedModeBanner: false,

      // Themes — user can switch in Settings (persisted to Hive user_prefs).
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,

      // Router
      routerConfig: router,

      // Localisation (Indian locale for INR formatting)
      locale: const Locale('en', 'IN'),
      supportedLocales: const [
        Locale('en', 'IN'),
        Locale('en', 'US'),
      ],

      // Global builder for connectivity banner
      builder: (context, child) {
        return _AppBuilder(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

/// Wraps the entire app to inject the offline banner at the top level
class _AppBuilder extends ConsumerWidget {
  const _AppBuilder({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // MediaQuery text scale factor clamp (prevent huge accessibility text breaking layouts)
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
        ),
      ),
      child: child,
    );
  }
}
