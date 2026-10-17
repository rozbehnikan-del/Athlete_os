import 'package:athlete_os/src/app/athlete_os_app.dart';
import 'package:athlete_os/src/features/training/application/workout_providers.dart';
import 'package:athlete_os/src/features/training/data/repositories/mock_workout_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_viewport.dart';
import 'helpers/fake_auth_repository.dart';
import 'package:athlete_os/src/features/auth/application/auth_controller.dart';

Future<void> tapCompleteSet(WidgetTester tester) async {
  final finder = find.text('Complete Set');

  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();

  expect(finder.hitTestable(), findsOneWidget);

  await tester.tap(finder.hitTestable());
  await tester.pumpAndSettle();
}

Future<void> expectVisibleText(String text, WidgetTester tester) async {
  final finder = find.text(text);

  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();

  expect(finder.hitTestable(), findsOneWidget);
}

Widget testApp() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWith((ref) => FakeAuthRepository()),
      workoutRepositoryProvider.overrideWith((ref) => MockWorkoutRepository()),
    ],
    child: const AthleteOSApp(),
  );
}

void main() {
  testWidgets('AthleteOS starts on onboarding and enters app', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('Train.\nProgress.\nCompete.'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Good Morning'), findsOneWidget);
    expect(find.text("Today's Workout"), findsOneWidget);
  });

  testWidgets('English is the default locale', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Persian locale can be selected', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.grid_view_rounded).hitTestable());
    await tester.pumpAndSettle();

    final persianOption = find.widgetWithText(RadioListTile<Locale>, 'فارسی');
    await tester.ensureVisible(persianOption);
    await tester.pumpAndSettle();
    await tester.tap(persianOption);
    await tester.pumpAndSettle();

    expect(find.text('خانه').hitTestable(), findsWidgets);
  });

  testWidgets('main navigation routes correctly', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.show_chart_rounded).hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Back Squat').hitTestable(), findsOneWidget);
  });

  testWidgets('Start Workout navigates to workout session', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Workout').hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Coach target').hitTestable(), findsOneWidget);
    expect(find.text('Back Squat').hitTestable(), findsOneWidget);
  });

  testWidgets('Completing and editing a set updates UI', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Workout').hitTestable());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '7');
    await tester.pumpAndSettle();
    await tapCompleteSet(tester);

    await expectVisibleText('Set 2 of 4', tester);
  });

  testWidgets('invalid reps cannot complete a set', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Workout').hitTestable());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    await tapCompleteSet(tester);

    expect(
      find.text('Check reps, weight, and RPE before completing the set.'),
      findsOneWidget,
    );
    await expectVisibleText('Set 1 of 4', tester);
  });

  testWidgets('invalid weight cannot complete a set', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Workout').hitTestable());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), '1..5');
    await tester.pumpAndSettle();
    await tapCompleteSet(tester);

    expect(
      find.text('Check reps, weight, and RPE before completing the set.'),
      findsOneWidget,
    );
    await expectVisibleText('Set 1 of 4', tester);
  });

  testWidgets('Training Today and History tabs work', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.fitness_center_rounded).hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Start Workout').hitTestable(), findsOneWidget);
    await tester.tap(find.text('History').hitTestable());
    await tester.pumpAndSettle();

    expect(
      find.text('No completed workouts yet').hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.text('Today').hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Start Workout').hitTestable(), findsOneWidget);
  });

  testWidgets('Navigation through sets and exercises works', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Workout').hitTestable());
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tapCompleteSet(tester);
    }

    await expectVisibleText('Romanian Deadlift', tester);
    await expectVisibleText('Exercise 2 of 3', tester);
  });

  testWidgets('Finish Workout confirmation appears', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Workout').hitTestable());
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      await tapCompleteSet(tester);
    }

    expect(find.text('Workout complete').hitTestable(), findsOneWidget);
    expect(find.text('Finish Workout').hitTestable(), findsOneWidget);
  });

  testWidgets('Completed workout appears in History', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Workout').hitTestable());
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      await tapCompleteSet(tester);
    }
    await tester.tap(find.text('Finish Workout').hitTestable());
    await tester.pumpAndSettle();

    expect(find.text("Today's Workout").hitTestable(), findsOneWidget);
    expect(
      find.textContaining('10 sets completed').hitTestable(),
      findsOneWidget,
    );
  });
}
