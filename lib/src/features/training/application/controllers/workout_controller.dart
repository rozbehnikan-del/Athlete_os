import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_history_entry.dart';
import '../../domain/entities/workout_result.dart';
import '../workout_providers.dart';

final workoutControllerProvider =
    AsyncNotifierProvider<WorkoutController, Workout?>(WorkoutController.new);

final workoutHistoryProvider = FutureProvider<List<WorkoutHistoryEntry>>(
  (ref) => ref.watch(workoutRepositoryProvider).getWorkoutHistory(),
);

class WorkoutController extends AsyncNotifier<Workout?> {
  @override
  Future<Workout?> build() {
    return ref.watch(workoutRepositoryProvider).getTodayWorkout();
  }

  Future<void> submitResult(WorkoutResult result) async {
    await ref.read(workoutRepositoryProvider).submitWorkoutResult(result);
    ref.invalidate(workoutHistoryProvider);
  }
}
