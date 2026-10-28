import 'package:athlete_os/src/app/application/app_theme_controller.dart';
import 'package:athlete_os/src/app/athlete_os_app.dart';
import 'package:athlete_os/src/core/theme/app_theme.dart';
import 'package:athlete_os/src/features/auth/application/auth_controller.dart';
import 'package:athlete_os/src/features/training/application/workout_providers.dart';
import 'package:athlete_os/src/features/training/data/repositories/mock_workout_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_auth_repository.dart';

class MemoryThemePreferences extends Fake implements SharedPreferencesAsync {
  MemoryThemePreferences({
    String? value,
    this.failRead = false,
    this.failWrite = false,
  }) : _values = {'value': value};
  final Map<String, String?> _values;
  String? get value => _values['value'];
  final bool failRead;
  final bool failWrite;

  @override
  Future<String?> getString(String key) async {
    expect(key, AppThemeController.preferenceKey);
    if (failRead) throw StateError('Storage unavailable');
    return value;
  }

  @override
  Future<void> setString(String key, String value) async {
    expect(key, AppThemeController.preferenceKey);
    if (failWrite) throw StateError('Storage unavailable');
    _values['value'] = value;
  }
}

void main() {
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    test('${theme.brightness} uses neutral Material interaction colors', () {
      final scheme = theme.colorScheme;
      expect(scheme.primary, isNot(AppColors.primaryGreen));
      expect(scheme.secondary, isNot(AppColors.primaryGreen));
      expect(theme.progressIndicatorTheme.color, scheme.primary);
      expect(theme.textSelectionTheme.cursorColor, scheme.primary);
      expect(
        (theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder)
            .borderSide
            .color,
        scheme.primary,
      );
      final contrast =
          (scheme.onSurface.computeLuminance() + 0.05) /
          (scheme.surface.computeLuminance() + 0.05);
      expect(contrast > 1 ? contrast : 1 / contrast, greaterThan(4.5));
    });
  }

  ProviderContainer containerFor(MemoryThemePreferences preferences) {
    final container = ProviderContainer(
      overrides: [themePreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('theme defaults to system and unknown stored values are safe', () async {
    expect(
      await containerFor(
        MemoryThemePreferences(),
      ).read(appThemeControllerProvider.future),
      ThemeMode.system,
    );
    expect(
      await containerFor(
        MemoryThemePreferences(value: 'invalid'),
      ).read(appThemeControllerProvider.future),
      ThemeMode.system,
    );
  });

  test(
    'light/dark/system selections persist across controller recreation',
    () async {
      final preferences = MemoryThemePreferences();
      for (final mode in [ThemeMode.light, ThemeMode.dark, ThemeMode.system]) {
        final container = containerFor(preferences);
        await container.read(appThemeControllerProvider.future);
        await container
            .read(appThemeControllerProvider.notifier)
            .setThemeMode(mode);
        expect(container.read(appThemeControllerProvider).requireValue, mode);
        expect(preferences.value, mode.name);
        final restarted = containerFor(preferences);
        expect(await restarted.read(appThemeControllerProvider.future), mode);
      }
    },
  );

  test('storage read and write failures fall back to system', () async {
    expect(
      await containerFor(
        MemoryThemePreferences(failRead: true),
      ).read(appThemeControllerProvider.future),
      ThemeMode.system,
    );
    final container = containerFor(MemoryThemePreferences(failWrite: true));
    await container.read(appThemeControllerProvider.future);
    await container
        .read(appThemeControllerProvider.notifier)
        .setThemeMode(ThemeMode.dark);
    expect(
      container.read(appThemeControllerProvider).requireValue,
      ThemeMode.system,
    );
  });

  Future<void> openApp(
    WidgetTester tester, {
    required bool authenticated,
    String mode = 'dark',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themePreferencesProvider.overrideWithValue(
            MemoryThemePreferences(value: mode),
          ),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(token: authenticated ? 'test-token' : null),
          ),
          workoutRepositoryProvider.overrideWith(
            (ref) => MockWorkoutRepository(),
          ),
        ],
        child: const AthleteOSApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final mode in ['light', 'dark']) {
    testWidgets('$mode auth welcome and focused login use neutral theme', (
      tester,
    ) async {
      await openApp(tester, authenticated: false, mode: mode);
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme!.brightness, Brightness.light);
      expect(materialApp.darkTheme!.brightness, Brightness.dark);
      expect(
        materialApp.themeMode,
        mode == 'dark' ? ThemeMode.dark : ThemeMode.light,
      );
      expect(find.text("Let's get started"), findsOneWidget);
      await tester.tap(find.text('Continue with Email'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextFormField).first);
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(TextFormField).first);
      final theme = Theme.of(context);
      expect(
        theme.brightness,
        mode == 'dark' ? Brightness.dark : Brightness.light,
      );
      expect(
        (theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder)
            .borderSide
            .color,
        theme.colorScheme.primary,
      );
      expect(
        theme.textSelectionTheme.cursorColor,
        isNot(AppColors.primaryGreen),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('system mode follows platform brightness without leaving auth', (
    tester,
  ) async {
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    await openApp(tester, authenticated: false, mode: 'system');
    expect(
      Theme.of(tester.element(find.text("Let's get started"))).brightness,
      Brightness.dark,
    );
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.light;
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text("Let's get started"))).brightness,
      Brightness.light,
    );
  });

  testWidgets(
    'dark Home, Training Today, History, session and More render; preference changes keep route',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await openApp(tester, authenticated: true);
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      expect(find.text("TODAY'S TRAINING"), findsOneWidget);
      expect(
        Theme.of(tester.element(find.text('Good morning, Ali'))).brightness,
        Brightness.dark,
      );
      await tester.tap(find.byIcon(Icons.fitness_center_rounded).hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Start Workout').hitTestable(), findsOneWidget);
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('No completed workouts yet'), findsOneWidget);
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Workout').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Coach target'), findsOneWidget);
      expect(
        Theme.of(tester.element(find.byType(TextField).first)).brightness,
        Brightness.dark,
      );
      await tester.tap(find.byIcon(Icons.grid_view_rounded).hitTestable());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Appearance'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Light'));
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light,
      );
      expect(find.text('Appearance'), findsOneWidget);
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
