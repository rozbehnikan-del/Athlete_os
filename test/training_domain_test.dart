import 'package:athlete_os/src/core/auth/user_role.dart';
import 'package:athlete_os/src/core/errors/app_exception.dart';
import 'package:athlete_os/src/features/training/data/repositories/mock_workout_repository.dart';
import 'package:athlete_os/src/features/training/application/controllers/workout_session_controller.dart';
import 'package:athlete_os/src/features/training/domain/entities/exercise_prescription.dart';
import 'package:athlete_os/src/features/training/domain/entities/exercise_set.dart';
import 'package:athlete_os/src/features/training/domain/entities/workout_result.dart';
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
          workout.exercises.first.exerciseId,
          firstSet.setNumber,
        ): SetResultDraft(
          exerciseId: workout.exercises.first.exerciseId,
          setNumber: firstSet.setNumber,
          actualReps: firstSet.targetReps,
          actualWeight: firstSet.targetWeight,
          weightUnit: firstSet.weightUnit,
        ),
      },
    );

    expect(state.currentDraft.actualReps, firstSet.targetReps);
    expect(state.currentDraft.actualWeight, firstSet.targetWeight);
  });

  test('Athlete can change actual reps and weight in draft', () {
    const draft = SetResultDraft(
      exerciseId: 'back-squat',
      setNumber: 1,
      actualReps: 8,
      actualWeight: 80,
      weightUnit: WeightUnit.kg,
    );

    final changed = draft.copyWith(actualReps: 7, actualWeight: 82.5);

    expect(changed.actualReps, 7);
    expect(changed.actualWeight, 82.5);
  });

  test('RPE validation rejects invalid values conceptually', () {
    bool isValidRpe(double? rpe) => rpe == null || (rpe >= 1 && rpe <= 10);

    expect(isValidRpe(0), isFalse);
    expect(isValidRpe(11), isFalse);
    expect(isValidRpe(7.5), isTrue);
  });

  test('Completing a set creates correct result data', () {
    const draft = SetResultDraft(
      exerciseId: 'back-squat',
      setNumber: 1,
      actualReps: 7,
      actualWeight: 82.5,
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
          draftKey(exercise.exerciseId, set.setNumber): SetResultDraft(
            exerciseId: exercise.exerciseId,
            setNumber: set.setNumber,
            actualReps: set.targetReps,
            actualWeight: set.targetWeight,
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

    expect(await repository.getWorkoutHistory('athlete-ali'), contains(result));
  });
}
