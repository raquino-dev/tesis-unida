import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/pilot_local_store.dart';

/// El diseño Finanza inicia en modo claro; la elección previa se conserva.
class AppThemeModeNotifier extends StateNotifier<ThemeMode> {
  AppThemeModeNotifier()
    : super(PilotLocalStore.darkTheme ? ThemeMode.dark : ThemeMode.light);

  void toggle() =>
      setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  void setMode(ThemeMode mode) {
    state = mode;
    PilotLocalStore.saveDarkTheme(mode == ThemeMode.dark);
  }
}

final themeModeProvider =
    StateNotifierProvider<AppThemeModeNotifier, ThemeMode>(
      (ref) => AppThemeModeNotifier(),
    );
