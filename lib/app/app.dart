import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_provider.dart';

class FinanzasApp extends ConsumerWidget {
  const FinanzasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Finanzas Inteligentes (Prototipo)',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Banner(
        message: 'PROTOTIPO',
        location: BannerLocation.topEnd,
        color: Theme.of(context).colorScheme.primary,
        child: child ?? const SizedBox.shrink(),
      ),
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
