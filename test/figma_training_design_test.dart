import 'package:athlete_os/src/core/theme/app_theme.dart';
import 'package:athlete_os/src/core/theme/figma_v1_tokens.dart';
import 'package:athlete_os/src/features/training/domain/entities/crossfit.dart';
import 'package:athlete_os/src/features/training/domain/entities/exercise_prescription.dart';
import 'package:athlete_os/src/features/training/domain/entities/exercise_set.dart';
import 'package:athlete_os/src/features/training/domain/entities/workout.dart';
import 'package:athlete_os/src/features/training/presentation/training_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Figma training cards use real ordered blocks, never mock scores',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final workout = Workout(
      id: 'session1',
      title: 'CrossFit Mixed',
      category: 'CrossFit',
      focus: 'Conditioning',
      exercises: [
        ExercisePrescription(
          id: 'sq1',
          exerciseId: 'squat',
          exerciseSlug: 'back-squat',
          name: 'Back Squat',
          sets: const [
            ExerciseSet(id: 'set1', setNumber: 1,
                targetReps: 5, targetWeight: 80, weightUnit: WeightUnit.kg),
          ],
        ),
      ],
      session: const TrainingSession(id: 'session', blocks: [
        TrainingBlock(id: 'w', order: 0, type: TrainingBlockType.warmup,
            title: 'Movement Prep',
            prescription: {'description': 'Bike · Hip flow'}),
        TrainingBlock(id: 's', order: 1, type: TrainingBlockType.strength,
            title: 'Squat session', prescription: {}),
        TrainingBlock(id: 'm', order: 2, type: TrainingBlockType.metcon,
            title: 'Wall Ball / Burpee',
            prescription: {},
            wod: WodDefinition(
              id: 'amrap', format: WodFormat.amrap,
              scoreType: WodScoreType.roundsReps,
              durationSeconds: 720, scalingOptions: [], scoreConfig: {},
            )),
        TrainingBlock(id: 'a', order: 3, type: TrainingBlockType.accessory,
            title: 'Trunk', prescription: {'description': '3 × 12 sit-ups'}),
      ]),
    );

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FigmaTrainingBlockList(workout: workout),
      )),
    ));
    await tester.pumpAndSettle();

    expect(find.text('WARM-UP'), findsOneWidget);
    expect(find.text('Movement Prep'), findsOneWidget);
    expect(find.text('STRENGTH'), findsOneWidget);
    expect(find.text('Back Squat'), findsOneWidget);
    expect(find.text('METCON'), findsOneWidget);
    expect(find.text('AMRAP 12'), findsOneWidget);
    expect(find.text('ACCESSORY'), findsOneWidget);
    expect(find.text('Trunk'), findsOneWidget);
    expect(find.text('7 rounds + 14 reps'), findsNothing);
    final button = find.byKey(const Key('training-start-workout'));
    await tester.ensureVisible(button);
    expect(tester.getSize(button).height, FigmaV1Tokens.primaryButtonHeight);
    expect(tester.takeException(), isNull);
  });
}
