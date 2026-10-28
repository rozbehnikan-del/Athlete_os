import 'package:athlete_os/src/features/coach/application/coach_providers.dart';
import 'package:athlete_os/src/features/coach/domain/coach_models.dart';
import 'package:athlete_os/src/features/coach/presentation/coach_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Coach Dashboard uses real roster and no fabricated KPI values',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        coachRosterProvider.overrideWith((ref) async => [
          const CoachAthlete(
            id: 'athlete-1',
            name: 'Ali',
            email: 'ali@test.local',
          ),
        ]),
      ],
      child: const MaterialApp(
        home: CoachHomeScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Good morning, Coach'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Athletes'), findsWidgets);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('Ali'), findsOneWidget);
    expect(find.textContaining('1 assigned athletes'), findsOneWidget);
    expect(find.text('No verified alerts available'), findsOneWidget);
    expect(find.text('91%'), findsNothing);
    expect(find.text('6'), findsNothing);
    expect(find.text('Not available'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Coach Dashboard adapts to mobile without sidebar',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        coachRosterProvider.overrideWith((ref) async => <CoachAthlete>[]),
      ],
      child: const MaterialApp(home: CoachHomeScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Good morning, Coach'), findsOneWidget);
    expect(find.text('No athletes assigned yet.'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
