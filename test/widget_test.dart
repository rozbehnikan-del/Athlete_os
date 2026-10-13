import 'package:athlete_os/src/app/athlete_os_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_viewport.dart';

void main() {
  testWidgets('AthleteOS starts on onboarding and enters app', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AthleteOSApp()));

    expect(find.text('Train.\nProgress.\nCompete.'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Good Morning'), findsOneWidget);
    expect(find.text("Today's Workout"), findsOneWidget);
  });

  testWidgets('English is the default locale', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AthleteOSApp()));

    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Persian locale can be selected', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(const ProviderScope(child: AthleteOSApp()));

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
    await tester.pumpWidget(const ProviderScope(child: AthleteOSApp()));

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.show_chart_rounded).hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Back Squat').hitTestable(), findsOneWidget);
  });

  testWidgets('Start Workout navigates to workout session', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(const ProviderScope(child: AthleteOSApp()));

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Workout').hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Coach target').hitTestable(), findsOneWidget);
    expect(find.text('Back Squat').hitTestable(), findsOneWidget);
  });

  testWidgets('Completing and editing a set updates UI', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(const ProviderScope(child: AthleteOSApp()));

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Workout').hitTestable());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '7');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Set').hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Set 2 of 4').hitTestable(), findsOneWidget);
  });

  testWidgets('invalid reps cannot complete a set', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(const ProviderScope(child: AthleteOSApp()));

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Workout').hitTestable());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Set').hitTestable());
    await tester.pumpAndSettle();

    expect(
      find.text('Check reps, weight, and RPE before completing the set.'),
      findsOneWidget,
    );
    expect(find.text('Set 1 of 4').hitTestable(), findsOneWidget);
  });

  testWidgets('invalid weight cannot complete a set', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(const ProviderScope(child: AthleteOSApp()));

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Workout').hitTestable());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), '1..5');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Set').hitTestable());
    await tester.pumpAndSettle();

    expect(
      find.text('Check reps, weight, and RPE before completing the set.'),
      findsOneWidget,
    );
    expect(find.text('Set 1 of 4').hitTestable(), findsOneWidget);
  });

  testWidgets('Training Today and History tabs work', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(const ProviderScope(child: AthleteOSApp()));

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
    await tester.pumpWidget(const ProviderScope(child: AthleteOSApp()));

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Workout').hitTestable());
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Complete Set').hitTestable());
      await tester.pumpAndSettle();
    }

    expect(find.text('Romanian Deadlift').hitTestable(), findsOneWidget);
    expect(find.text('Exercise 2 of 3').hitTestable(), findsOneWidget);
  });

  testWidgets('Finish Workout confirmation appears', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(const ProviderScope(child: AthleteOSApp()));

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Workout').hitTestable());
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      await tester.tap(find.text('Complete Set').hitTestable());
      await tester.pumpAndSettle();
    }

    expect(find.text('Workout complete').hitTestable(), findsOneWidget);
    expect(find.text('Finish Workout').hitTestable(), findsOneWidget);
  });

  testWidgets('Completed workout appears in History', (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(const ProviderScope(child: AthleteOSApp()));

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Workout').hitTestable());
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      await tester.tap(find.text('Complete Set').hitTestable());
      await tester.pumpAndSettle();
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
