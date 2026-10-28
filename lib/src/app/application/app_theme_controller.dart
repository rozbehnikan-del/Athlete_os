import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themePreferencesProvider = Provider<SharedPreferencesAsync>(
  (ref) => SharedPreferencesAsync(),
);
final appThemeControllerProvider =
    AsyncNotifierProvider<AppThemeController, ThemeMode>(
      AppThemeController.new,
    );

class AppThemeController extends AsyncNotifier<ThemeMode> {
  static const preferenceKey = 'athlete_os_theme_mode';
  Future<void> _pendingWrite = Future.value();
  int _selectionVersion = 0;

  @override
  Future<ThemeMode> build() async {
    try {
      final stored = await ref
          .watch(themePreferencesProvider)
          .getString(preferenceKey);
      return ThemeMode.values.firstWhere(
        (mode) => mode.name == stored,
        orElse: () => ThemeMode.light,
      );
    } catch (_) {
      return ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await future;
    if (!ref.mounted) return;
    final selectionVersion = ++_selectionVersion;
    state = AsyncData(mode);
    // Keep rapid selections in order so the last choice is also the stored one.
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        await ref
            .read(themePreferencesProvider)
            .setString(preferenceKey, mode.name);
      } catch (_) {
        if (ref.mounted && selectionVersion == _selectionVersion) {
          state = const AsyncData(ThemeMode.light);
        }
      }
    });
    await _pendingWrite;
  }
}
