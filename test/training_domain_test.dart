import 'package:athlete_os/src/core/auth/user_role.dart';
import 'package:athlete_os/src/core/errors/app_exception.dart';
import 'package:athlete_os/src/features/training/data/repositories/mock_workout_repository.dart';
import 'package:athlete_os/src/features/training/application/controllers/workout_session_controller.dart';
import 'package:athlete_os/src/features/training/application/workout_providers.dart';
import 'package:athlete_os/src/features/training/domain/entities/exercise_prescription.dart';
import 'package:athlete_os/src/features/training/domain/entities/exercise_set.dart';
import 'package:athlete_os/src/features/training/domain/entities/workout.dart';
import 'package:athlete_os/src/features/training/domain/entities/workout_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ExercisePrescription prescription() => ExercisePrescription(
    id: 'back-squat-prescription',
    exerciseId: 'back-squat',
    name: 'Back Squat',
    category: 'Strength',
    sets: const [
      ExerciseSet(
        setNumber: 1,
        targetReps: 8,
        targetWeight: 80,
        weightUnit: WeightUnit.kg,
      ),
    ],
  );

  test('athlete cannot modify coach-owned exercise prescription', () {
    expect(
      () => prescription().revise(actor: UserRole.athlete, category: 'Power'),
      throwsA(isA<UnauthorizedOperationException>()),
    );
  });

  test('doctor cannot modify coach-owned exercise prescription', () {
    expect(
      () => prescription().revise(actor: UserRole.doctor, category: 'Power'),
      throwsA(isA<UnauthorizedOperationException>()),
    );
  });

  test('nutritionist cannot modify coach-owned exercise prescription', () {
    expect(
      () => prescription().revise(
        actor: UserRole.nutritionist,
        category: 'Power',
      ),
      throwsA(isA<UnauthorizedOperationException>()),
    );
  });

  test('coach can modify coach-owned exercise prescription', () {
    final revised = prescription().revise(
      actor: UserRole.coach,
      category: 'Power',
    );

    expect(revised.category, 'Power');
  });

  test('admin can modify coach-owned exercise prescription', () {
    final revised = prescription().revise(
      actor: UserRole.admin,
      category: 'Power',
    );

    expect(revised.category, 'Power');
  });

  test('ExerciseSet stores structured numeric target values', () {
    const set = ExerciseSet(
      setNumber: 1,
      targetReps: 8,
      targetWeight: 80,
      weightUnit: WeightUnit.kg,
    );

    expect(set.targetWeight, 80);
    expect(set.weightUnit, WeightUnit.kg);
  });

  test('ExerciseSet contains no athlete completion state', () {
    const dynamic set = ExerciseSet(
      setNumber: 1,
      targetReps: 8,
      targetWeight: 80,
      weightUnit: WeightUnit.kg,
    );

    expect(() => set.completed, throwsA(isA<NoSuchMethodError>()));
  });

  test('athlete can submit actual workout results', () async {
    final repository = MockWorkoutRepository();
    final result = WorkoutResult(
      workoutId: 'today-lower-strength',
      athleteId: 'athlete-ali',
      completedAt: DateTime.utc(2026, 10, 13),
      setResults: const [
        SetResult(
          prescriptionId: 'back-squat-prescription',
          exerciseId: 'back-squat',
          setNumber: 1,
          actualReps: 8,
          actualWeight: 80,
          weightUnit: WeightUnit.kg,
          completed: true,
          rpe: 7.5,
        ),
      ],
      notes: 'Felt strong.',
    );

    await repository.submitWorkoutResult(result);

    expect(repository.submittedResults, contains(result));
  });

  test('MockWorkoutRepository returns structured workout data', () async {
    final repository = MockWorkoutRepository();

    final workout = await repository.getTodayWorkout('athlete-ali');
    final firstSet = workout.exercises.first.sets.first;

    expect(workout.id, 'today-lower-strength');
    expect(workout.exercises.first.exerciseId, 'back-squat');
    expect(firstSet.targetReps, 8);
    expect(firstSet.targetWeight, 80);
    expect(firstSet.weightUnit, WeightUnit.kg);
    expect(
      workout.exercises.every((exercise) => exercise.sets.isNotEmpty),
      isTrue,
    );
  });

  test('MockWorkoutRepository returns workout by id', () async {
    final repository = MockWorkoutRepository();

    final workout = await repository.getWorkoutById(
      athleteId: 'athlete-ali',
      workoutId: 'today-lower-strength',
    );

    expect(workout.id, 'today-lower-strength');
  });

  test('WorkoutSession initializes actual values from target', () async {
    final repository = MockWorkoutRepository();
    final workout = await repository.getTodayWorkout('athlete-ali');
    final firstSet = workout.exercises.first.sets.first;
    final state = WorkoutSessionState(
      workout: workout,
      currentExerciseIndex: 0,
      currentSetIndex: 0,
      drafts: {
        draftKey(
          workout.exercises.first.id,
          firstSet.setNumber,
        ): SetResultDraft(
          prescriptionId: workout.exercises.first.id,
          exerciseId: workout.exercises.first.exerciseId,
          setNumber: firstSet.setNumber,
          repsInput: firstSet.targetReps.toString(),
          weightInput: firstSet.targetWeight.toString(),
          weightUnit: firstSet.weightUnit,
        ),
      },
    );

    expect(state.currentDraft.actualReps, firstSet.targetReps);
    expect(state.currentDraft.actualWeight, firstSet.targetWeight);
  });

  test('Athlete can change actual reps and weight in draft', () {
    const draft = SetResultDraft(
      prescriptionId: 'back-squat-prescription',
      exerciseId: 'back-squat',
      setNumber: 1,
      repsInput: '8',
      weightInput: '80',
      weightUnit: WeightUnit.kg,
    );

    final changed = draft.copyWith(repsInput: '7', weightInput: '82.5');

    expect(changed.actualReps, 7);
    expect(changed.actualWeight, 82.5);
  });

  test('RPE validation rejects invalid values on draft', () {
    const draft = SetResultDraft(
      prescriptionId: 'back-squat-prescription',
      exerciseId: 'back-squat',
      setNumber: 1,
      repsInput: '8',
      weightInput: '80',
      weightUnit: WeightUnit.kg,
    );

    expect(draft.copyWith(rpe: 0).isValid, isFalse);
    expect(draft.copyWith(rpe: 11).isValid, isFalse);
    expect(draft.copyWith(rpe: 7.5).isValid, isTrue);
  });

  test('Completing a set creates correct result data', () {
    const draft = SetResultDraft(
      prescriptionId: 'back-squat-prescription',
      exerciseId: 'back-squat',
      setNumber: 1,
      repsInput: '7',
      weightInput: '82.5',
      weightUnit: WeightUnit.kg,
      completed: true,
      rpe: 8,
    );

    final result = draft.toResult();

    expect(result.exerciseId, 'back-squat');
    expect(result.actualReps, 7);
    expect(result.actualWeight, 82.5);
    expect(result.completed, isTrue);
  });

  test('Completing full session builds correct WorkoutResult', () async {
    final repository = MockWorkoutRepository();
    final workout = await repository.getTodayWorkout('athlete-ali');
    final drafts = {
      for (final exercise in workout.exercises)
        for (final set in exercise.sets)
          draftKey(exercise.id, set.setNumber): SetResultDraft(
            prescriptionId: exercise.id,
            exerciseId: exercise.exerciseId,
            setNumber: set.setNumber,
            repsInput: set.targetReps.toString(),
            weightInput: set.targetWeight.toString(),
            weightUnit: set.weightUnit,
            completed: true,
          ),
    };
    final state = WorkoutSessionState(
      workout: workout,
      currentExerciseIndex: 0,
      currentSetIndex: 0,
      drafts: drafts,
      workoutNote: 'Felt strong today',
    );

    final result = state.buildResult(
      athleteId: 'athlete-ali',
      completedAt: DateTime.utc(2026, 10, 13),
    );

    expect(result.setResults.length, state.totalSets);
    expect(result.notes, 'Felt strong today');
  });

  test('Workout history returns submitted result', () async {
    final repository = MockWorkoutRepository();
    final result = WorkoutResult(
      workoutId: 'today-lower-strength',
      athleteId: 'athlete-ali',
      completedAt: DateTime.utc(2026, 10, 13),
      setResults: const [
        SetResult(
          prescriptionId: 'back-squat-prescription',
          exerciseId: 'back-squat',
          setNumber: 1,
          actualReps: 8,
          actualWeight: 80,
          weightUnit: WeightUnit.kg,
          completed: true,
        ),
      ],
    );

    await repository.submitWorkoutResult(result);

    final history = await repository.getWorkoutHistory('athlete-ali');
    expect(history.single.workoutId, result.workoutId);
    expect(history.single.workoutTitle, "Today's Workout");
  });

  test('WorkoutSessionController updates values and validates input', () async {
    final repository = MockWorkoutRepository();
    final container = ProviderContainer(
      overrides: [workoutRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final provider = workoutSessionControllerProvider('today-lower-strength');
    final initial = await container.read(provider.future);
    final notifier = container.read(provider.notifier);

    expect(initial.currentDraft.actualReps, 8);
    expect(initial.currentDraft.actualWeight, 80);

    notifier.updateActualReps(7);
    notifier.updateActualWeight(82.5);
    notifier.updateRpe(8);

    final changed = container.read(provider).requireValue.currentDraft;
    expect(changed.actualReps, 7);
    expect(changed.actualWeight, 82.5);
    expect(changed.rpe, 8);

    expect(() => notifier.updateActualReps(-1), throwsArgumentError);
    expect(() => notifier.updateActualWeight(-1), throwsArgumentError);
    expect(() => notifier.updateRpe(11), throwsArgumentError);
  });

  test(
    'WorkoutSessionController blocks invalid raw input completion',
    () async {
      final repository = MockWorkoutRepository();
      final container = ProviderContainer(
        overrides: [workoutRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final provider = workoutSessionControllerProvider('today-lower-strength');
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);

      notifier.updateActualRepsInput('');
      expect(() => notifier.completeCurrentSet(), throwsStateError);

      notifier.updateActualRepsInput('8');
      notifier.updateActualWeightInput('1..5');
      expect(() => notifier.completeCurrentSet(), throwsStateError);
    },
  );

  test('WorkoutSessionController completes set and progresses', () async {
    final repository = MockWorkoutRepository();
    final container = ProviderContainer(
      overrides: [workoutRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final provider = workoutSessionControllerProvider('today-lower-strength');
    await container.read(provider.future);
    final notifier = container.read(provider.notifier);

    notifier.completeCurrentSet();

    final state = container.read(provider).requireValue;
    expect(state.completedSets, 1);
    expect(state.currentSetIndex, 1);
  });

  test('History metadata returns distinct workout title', () async {
    final workout = Workout(
      id: 'distinct-workout',
      title: 'Open Prep Strength',
      category: 'Strength',
      focus: 'Posterior Chain',
      exercises: [
        ExercisePrescription(
          id: 'deadlift-prescription',
          exerciseId: 'romanian-deadlift',
          name: 'Romanian Deadlift',
          sets: const [
            ExerciseSet(
              setNumber: 1,
              targetReps: 10,
              targetWeight: 70,
              weightUnit: WeightUnit.kg,
            ),
          ],
        ),
      ],
    );
    final repository = MockWorkoutRepository(workouts: [workout]);
    await repository.submitWorkoutResult(
      WorkoutResult(
        workoutId: workout.id,
        athleteId: 'athlete-ali',
        completedAt: DateTime.utc(2026, 10, 13),
        setResults: const [
          SetResult(
            prescriptionId: 'deadlift-prescription',
            exerciseId: 'romanian-deadlift',
            setNumber: 1,
            actualReps: 10,
            actualWeight: 70,
            weightUnit: WeightUnit.kg,
            completed: true,
          ),
        ],
      ),
    );

    final history = await repository.getWorkoutHistory('athlete-ali');

    expect(history.single.workoutTitle, 'Open Prep Strength');
  });

  test('Draft identity does not collide for repeated exercise ids', () {
    final workout = Workout(
      id: 'duplicate-exercise-workout',
      title: 'Duplicate Exercise Test',
      category: 'Strength',
      focus: 'Squat',
      exercises: [
        ExercisePrescription(
          id: 'back-squat-warmup',
          exerciseId: 'back-squat',
          name: 'Back Squat Warmup',
          sets: const [
            ExerciseSet(
              setNumber: 1,
              targetReps: 5,
              targetWeight: 40,
              weightUnit: WeightUnit.kg,
            ),
          ],
        ),
        ExercisePrescription(
          id: 'back-squat-strength',
          exerciseId: 'back-squat',
          name: 'Back Squat Strength',
          sets: const [
            ExerciseSet(
              setNumber: 1,
              targetReps: 3,
              targetWeight: 100,
              weightUnit: WeightUnit.kg,
            ),
          ],
        ),
      ],
    );
    final drafts = {
      for (final exercise in workout.exercises)
        for (final set in exercise.sets)
          draftKey(exercise.id, set.setNumber): SetResultDraft(
            prescriptionId: exercise.id,
            exerciseId: exercise.exerciseId,
            setNumber: set.setNumber,
            repsInput: set.targetReps.toString(),
            weightInput: set.targetWeight.toString(),
            weightUnit: set.weightUnit,
          ),
    };

    expect(drafts.keys, contains('back-squat-warmup:1'));
    expect(drafts.keys, contains('back-squat-strength:1'));
    expect(drafts.length, 2);
  });
}
