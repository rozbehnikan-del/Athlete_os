import 'package:athlete_os/src/core/auth/user_role.dart';
import 'package:athlete_os/src/core/errors/app_exception.dart';
import 'package:athlete_os/src/features/training/data/repositories/mock_workout_repository.dart';
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
  });
}
