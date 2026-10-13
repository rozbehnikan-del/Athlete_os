import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_result.dart';
import '../workout_providers.dart';

final workoutControllerProvider =
    AsyncNotifierProvider<WorkoutController, Workout>(WorkoutController.new);

class WorkoutController extends AsyncNotifier<Workout> {
  static const _athleteId = 'athlete-ali';

  @override
  Future<Workout> build() {
    return ref.watch(workoutRepositoryProvider).getTodayWorkout(_athleteId);
  }

  Future<void> submitResult(WorkoutResult result) async {
    await ref.read(workoutRepositoryProvider).submitWorkoutResult(result);
  }
}
