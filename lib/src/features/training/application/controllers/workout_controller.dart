import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_result.dart';
import '../workout_providers.dart';

final workoutControllerProvider =
    AsyncNotifierProvider<WorkoutController, Workout>(WorkoutController.new);

final workoutHistoryProvider = FutureProvider<List<WorkoutResult>>(
  (ref) => ref
      .watch(workoutRepositoryProvider)
      .getWorkoutHistory(WorkoutController.athleteId),
);

class WorkoutController extends AsyncNotifier<Workout> {
  static const athleteId = 'athlete-ali';

  @override
  Future<Workout> build() {
    return ref.watch(workoutRepositoryProvider).getTodayWorkout(athleteId);
  }

  Future<void> submitResult(WorkoutResult result) async {
    await ref.read(workoutRepositoryProvider).submitWorkoutResult(result);
    ref.invalidate(workoutHistoryProvider);
  }
}
