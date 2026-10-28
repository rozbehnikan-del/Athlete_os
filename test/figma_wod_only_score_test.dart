import 'package:athlete_os/src/features/training/application/workout_providers.dart';
import 'package:athlete_os/src/features/training/data/repositories/mock_workout_repository.dart';
import 'package:athlete_os/src/features/training/domain/entities/crossfit.dart';
import 'package:athlete_os/src/features/training/domain/entities/workout.dart';
import 'package:athlete_os/src/features/training/presentation/screens/crossfit_workout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WOD-only Figma Score Entry submits real For Time result',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final workout = Workout(
      id: 'fran-test',
      title: 'Fran',
      category: 'CrossFit',
      focus: '21-15-9',
      exercises: const [],
      session: const TrainingSession(
        id: 'session-fran',
        blocks: [
          TrainingBlock(
            id: 'fran-block',
            order: 0,
            type: TrainingBlockType.metcon,
            title: '21-15-9',
            prescription: {},
            wod: WodDefinition(
              id: 'fran-wod',
              format: WodFormat.forTime,
              scoreType: WodScoreType.time,
              timeCapSeconds: 720,
              scalingOptions: [ScalingLevel.rx, ScalingLevel.scaled],
              scoreConfig: {},
            ),
          ),
        ],
      ),
    );
    final repository = MockWorkoutRepository(workouts: [workout]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CrossFitWorkoutScreen(workoutId: 'fran-test'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fran'), findsOneWidget);
    expect(find.text('21-15-9 · For Time'), findsOneWidget);
    expect(find.text('Time cap 12:00'), findsOneWidget);
    expect(find.text('Session feedback'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('wod-score-fran-wod-Final time (mm:ss or seconds)')),
      '05:42',
    );
    await tester.pumpAndSettle();

    final save = find.byKey(const Key('wod-save-result'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('RESULT SAVED'), findsOneWidget);
    expect(repository.submittedResults, hasLength(1));
    expect(repository.submittedResults.single.wodResults.single.score.toJson(),
        {'type': 'time', 'seconds': 342});
    expect(tester.takeException(), isNull);
  });
}
