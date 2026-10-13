import '../entities/workout.dart';
import '../entities/workout_result.dart';

abstract interface class WorkoutRepository {
  Future<Workout> getTodayWorkout(String athleteId);

  Future<void> submitWorkoutResult(WorkoutResult result);
}
