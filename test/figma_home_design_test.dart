import 'package:athlete_os/src/app/athlete_os_app.dart';
import 'package:athlete_os/src/core/theme/figma_v1_tokens.dart';
import 'package:athlete_os/src/features/auth/application/auth_controller.dart';
import 'package:athlete_os/src/features/training/application/workout_providers.dart';
import 'package:athlete_os/src/features/training/data/repositories/mock_workout_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/test_viewport.dart';

void main() {
  test('Figma V1 foundational semantic colors are fixed', () {
    expect(FigmaV1Tokens.primary, const Color(0xFF141719));
    expect(FigmaV1Tokens.background, const Color(0xFFF7F8FA));
    expect(FigmaV1Tokens.success, const Color(0xFF17834B));
    expect(FigmaV1Tokens.cardRadius, 18);
    expect(FigmaV1Tokens.primaryButtonHeight, 54);
  });

  testWidgets('Athlete Home mirrors the compact Figma information hierarchy',
      (tester) async {
    await setMobileViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => FakeAuthRepository()),
          workoutRepositoryProvider.overrideWith(
              (ref) => MockWorkoutRepository()),
        ],
        child: const AthleteOSApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Good morning, Ali'), findsOneWidget);
    expect(find.text("TODAY'S TRAINING"), findsOneWidget);
    expect(find.text('Latest signal'), findsOneWidget);
    expect(find.text('Start Workout').hitTestable(), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);

    final greeting = tester.getTopLeft(find.byKey(const Key('home-greeting')));
    expect(greeting.dx, closeTo(20, 1));
    final startSize = tester.getSize(
      find.byKey(const Key('home-start-workout')),
    );
    expect(startSize.height, FigmaV1Tokens.primaryButtonHeight);
  });
}
