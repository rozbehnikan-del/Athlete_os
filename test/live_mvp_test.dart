// Opt-in: writes clearly named workouts for the known local demo athlete only.
// Credentials must come from a temporary --dart-define-from-file, never source.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:athlete_os/src/app/athlete_os_app.dart';
import 'package:athlete_os/src/app/application/app_theme_controller.dart';
import 'package:athlete_os/src/core/api/api_config.dart';
import 'package:athlete_os/src/core/api/api_providers.dart';
import 'package:athlete_os/src/features/training/application/controllers/workout_controller.dart';
import 'package:athlete_os/src/features/training/application/controllers/workout_session_controller.dart';
import 'helpers/fake_auth_repository.dart' show MemoryTokenStorage;

class _RealHttp extends HttpOverrides {}

void main() {
  const enabled = bool.fromEnvironment('RUN_LIVE_MVP');
  testWidgets(
    'LIVE coach assignment -> athlete execution -> PostgreSQL history -> progress',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      HttpOverrides.global = _RealHttp();
      addTearDown(() => HttpOverrides.global = null);
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
          apiConfigProvider.overrideWithValue(
            const ApiConfig(baseUrl: 'http://127.0.0.1:8011/'),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AthleteOSApp(),
        ),
      );

      Future<void> waitFor(Finder finder) async {
        for (var i = 0; i < 150; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump(const Duration(milliseconds: 100));
          if (finder.evaluate().isNotEmpty) {
            await tester.pump(const Duration(milliseconds: 300));
            return;
          }
        }
        expect(finder, findsWidgets, reason: 'Expected screen did not load');
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(finder.hitTestable());
        await tester.pump(const Duration(milliseconds: 300));
      }

      Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      Future<void> enter(String label, String value) async {
        await tester.ensureVisible(field(label));
        await tester.enterText(field(label), value);
        await tester.pump();
      }

      Future<void> login(String email, String password) async {
        await waitFor(find.text('Continue with Email'));
        await tap(find.text('Continue with Email'));
        await waitFor(field('Email'));
        await enter('Email', email);
        await enter('Password', password);
        await tap(find.text('Sign In'));
      }

      await login(
        'coach@athleteos.local',
        const String.fromEnvironment('DEMO_COACH_PASSWORD'),
      );
      await waitFor(find.text('My Athletes (1)'));
      // Exercise all three appearance preferences while keeping the coach route.
      for (final mode in [ThemeMode.dark, ThemeMode.light, ThemeMode.system]) {
        await tester.runAsync(
          () => container
              .read(appThemeControllerProvider.notifier)
              .setThemeMode(mode),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Coach Home'), findsOneWidget);
      }
      await tap(find.text('Ali'));
      await waitFor(find.text('Create Workout'));
      await tap(find.text('Create Workout'));
      await waitFor(field('Title'));
      final title =
          'MVP Flutter E2E ${DateTime.now().toUtc().toIso8601String()}';
      await enter('Title', title);
      await enter('Category (optional)', 'Verification');
      await enter('Focus (optional)', 'Completion');
      final exerciseDropdown = find
          .byType(DropdownButtonFormField<String>)
          .first;
      await tap(exerciseDropdown);
      await tester.pump(const Duration(milliseconds: 300));
      await tap(find.text('Back Squat').last);
      await enter('Set count', '2');
      await enter('Target reps', '5');
      await enter('Target weight', '0');
      await tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pump(const Duration(milliseconds: 300));
      await tap(find.text('kg').last);
      await enter('Coaching note (optional)', 'Scoped live MVP verification');
      await tap(find.text('Assign Workout'));
      await waitFor(find.text('Athlete Detail'));
      await waitFor(find.text(title));
      await tap(find.byTooltip('Back'));
      await tap(find.byTooltip('Sign Out'));
      await login(
        'ali@athleteos.local',
        const String.fromEnvironment('DEMO_ATHLETE_PASSWORD'),
      );
      await waitFor(find.text('Get Started'));
      await tap(find.text('Get Started'));
      await waitFor(find.text(title));
      final workout = await tester.runAsync(
        () => container.read(workoutControllerProvider.future),
      );
      expect(workout!.title, title);
      expect(workout.exercises.single.sets.length, 2);
      await tap(find.text('Start Workout'));
      await waitFor(find.text('Scoped live MVP verification'));
      final editable = find.byType(TextField);
      await tester.ensureVisible(editable.at(0));
      await tester.enterText(editable.at(0), '6');
      await tester.ensureVisible(editable.at(1));
      await tester.enterText(editable.at(1), '2.5');
      await tap(find.widgetWithText(ChoiceChip, '7'));
      await tap(find.text('Complete Set'));
      await tap(find.text('Review and finish'));
      await tap(find.text('Finish Workout'));
      await waitFor(find.textContaining('Completion Grade C'));
      final history = await tester.runAsync(
        () => container.read(workoutHistoryProvider.future),
      );
      final result = history!.firstWhere((e) => e.workoutId == workout.id);
      expect(result.completedSets, 1);
      expect(result.totalSets, 2);
      expect(result.completion.grade, 'C');
      expect(result.completion.percentage, 50);
      expect(result.setResults.single.actualReps, 6);
      expect(result.setResults.single.actualWeight, 2.5);
      expect(result.setResults.single.rpe, 7);
      final state = container
          .read(workoutSessionControllerProvider(workout.id))
          .requireValue;
      expect(state.finished, isTrue);
      await tap(find.byIcon(Icons.show_chart_rounded).hitTestable());
      await waitFor(find.text('Recent workout activity'));
      expect(find.text(title), findsOneWidget);
      expect(find.textContaining('1/2 sets\nCompletion Grade C'), findsWidgets);
      expect(tester.takeException(), isNull);
      // Persisted IDs are safe to report; never print credentials or bearer tokens.
      // ignore: avoid_print
      print(
        'LIVE VERIFIED workout=${workout.id} completed=1/2 grade=C actual_reps=6 actual_weight=2.5 rpe=7',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      container.read(apiClientProvider).close();
      await tester.pump(const Duration(seconds: 16));
    },
    skip: !enabled,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
