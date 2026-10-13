import 'package:athlete_os/src/core/auth/user_role.dart';
import 'package:athlete_os/src/core/errors/app_exception.dart';
import 'package:athlete_os/src/features/training/data/repositories/mock_workout_repository.dart';
import 'package:athlete_os/src/features/training/domain/entities/exercise_prescription.dart';
import 'package:athlete_os/src/features/training/domain/entities/exercise_set.dart';
import 'package:athlete_os/src/features/training/domain/entities/workout_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('athlete cannot modify coach-owned exercise prescription', () {
    final prescription = ExercisePrescription(
      id: 'back-squat',
      name: 'Back Squat',
      detail: '4 x 8 @ 80 kg',
      imagePath: 'assets/images/exercises/back_squat.jpg',
      sets: const [ExerciseSet(1, 8, '80 kg')],
    );

    expect(
      () => prescription.revise(actor: UserRole.athlete, detail: '3 x 5 @ 90 kg'),
      throwsA(isA<UnauthorizedOperationException>()),
    );
  });

  test('athlete can submit an actual workout result', () async {
    final repository = MockWorkoutRepository();
    const result = WorkoutResult(
      workoutId: 'today-lower-strength',
      athleteId: 'athlete-ali',
      completedSetIds: ['back-squat-1'],
      notes: 'Felt strong.',
    );

    await repository.submitWorkoutResult(result);

    expect(repository.submittedResults, contains(result));
  });

  test('MockWorkoutRepository returns expected workout data', () async {
    final repository = MockWorkoutRepository();

    final workout = await repository.getTodayWorkout('athlete-ali');

    expect(workout.id, 'today-lower-strength');
    expect(workout.exercises.first.name, 'Back Squat');
    expect(workout.exercises.first.sets.length, 4);
  });
}
