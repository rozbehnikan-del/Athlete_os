import '../entities/workout.dart';
import '../entities/workout_history_entry.dart';
import '../entities/workout_result.dart';

abstract interface class WorkoutRepository {
  Future<Workout?> getTodayWorkout(String athleteId);

  Future<Workout> getWorkoutById({
    required String athleteId,
    required String workoutId,
  });

  Future<void> submitWorkoutResult(WorkoutResult result);

  Future<List<WorkoutHistoryEntry>> getWorkoutHistory(String athleteId);
}
