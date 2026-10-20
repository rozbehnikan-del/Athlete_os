import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../progress/application/progress_providers.dart';

import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_history_entry.dart';
import '../../domain/entities/workout_result.dart';
import '../workout_providers.dart';

final workoutControllerProvider =
    AsyncNotifierProvider<WorkoutController, Workout?>(WorkoutController.new);

final workoutHistoryProvider =
    AsyncNotifierProvider<WorkoutHistoryController, List<WorkoutHistoryEntry>>(
      WorkoutHistoryController.new,
    );

class WorkoutHistoryController
    extends AsyncNotifier<List<WorkoutHistoryEntry>> {
  int _page = 1;
  bool _loadingMore = false;
  int _generation = 0;
  bool hasMore = false;
  @override
  Future<List<WorkoutHistoryEntry>> build() async {
    _page = 1;
    _loadingMore = false;
    final generation = ++_generation;
    final batch = await ref
        .watch(workoutRepositoryProvider)
        .getWorkoutHistory();
    if (generation == _generation) hasMore = batch.length == 20;
    return batch;
  }

  Future<void> loadMore() async {
    if (_loadingMore || !hasMore) return;
    _loadingMore = true;
    final generation = _generation;
    try {
      final batch = await ref
          .read(workoutRepositoryProvider)
          .getWorkoutHistory(page: _page + 1);
      if (!ref.mounted || generation != _generation) return;
      _page++;
      hasMore = batch.length == 20;
      state = AsyncData([...state.requireValue, ...batch]);
    } finally {
      if (generation == _generation) _loadingMore = false;
    }
  }
}

class WorkoutController extends AsyncNotifier<Workout?> {
  @override
  Future<Workout?> build() {
    return ref.watch(workoutRepositoryProvider).getTodayWorkout();
  }

  Future<void> submitResult(WorkoutResult result) async {
    await ref.read(workoutRepositoryProvider).submitWorkoutResult(result);
    ref.invalidate(workoutHistoryProvider);
    ref.invalidate(progressSummaryProvider);
  }
}
