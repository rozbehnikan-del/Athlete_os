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
}
