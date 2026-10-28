import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../progress/application/progress_providers.dart';
import '../../domain/entities/crossfit.dart';
import '../../domain/entities/exercise_set.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_result.dart';
import '../workout_providers.dart';
import 'crossfit_session_controller.dart';
import 'workout_controller.dart';
import 'workout_session_controller.dart';

final mixedSessionControllerProvider = AsyncNotifierProvider.family<
    MixedSessionController,
    MixedSessionState,
    String>(MixedSessionController.new);

class MixedSessionState {
  const MixedSessionState({
    required this.workout,
    required this.setDrafts,
    required this.wodDrafts,
    this.submitting = false,
    this.finished = false,
    this.error,
  });

  final Workout workout;
  final Map<String, SetResultDraft> setDrafts;
  final Map<String, WodResultDraft> wodDrafts;
  final bool submitting;
  final bool finished;
  final String? error;

  int get totalSets => setDrafts.length;
  int get completedSets =>
      setDrafts.values.where((draft) => draft.completed).length;

  double get progress {
    final wodCount = workout.scoredWods.length;
    final total = totalSets + wodCount;
    if (total == 0) return 0;
    final validWods = workout.scoredWods
        .where((wod) => wodDrafts[wod.id]?.toResult(wod) != null)
        .length;
    return (completedSets + validWods) / total;
  }

  MixedSessionState copyWith({
    Map<String, SetResultDraft>? setDrafts,
    Map<String, WodResultDraft>? wodDrafts,
    bool? submitting,
    bool? finished,
    String? error,
    bool clearError = false,
  }) {
    return MixedSessionState(
      workout: workout,
      setDrafts: setDrafts ?? this.setDrafts,
      wodDrafts: wodDrafts ?? this.wodDrafts,
      submitting: submitting ?? this.submitting,
      finished: finished ?? this.finished,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class MixedSessionController extends AsyncNotifier<MixedSessionState> {
  MixedSessionController(this.workoutId);

  final String workoutId;

  @override
  Future<MixedSessionState> build() async {
    final workout = await ref
        .watch(workoutRepositoryProvider)
        .getWorkoutById(workoutId: workoutId);

    if (!workout.isMixedSession) {
      throw StateError('Mixed session controller requires sets and WODs.');
    }

    final setDrafts = <String, SetResultDraft>{};
    for (final exercise in workout.exercises) {
      for (final set in exercise.sets) {
        setDrafts[draftKey(exercise.id, set.setNumber)] = SetResultDraft(
          setId: set.id,
          prescriptionId: exercise.id,
          exerciseId: exercise.exerciseId,
          setNumber: set.setNumber,
          repsInput: set.targetReps?.toString() ?? '',
          weightInput: _targetWeightInput(set),
          weightUnit: set.weightUnit,
        );
      }
    }

    final wodDrafts = <String, WodResultDraft>{
      for (final wod in workout.scoredWods)
        wod.id: WodResultDraft(
          wodId: wod.id,
          scaling: wod.scalingOptions.isNotEmpty
              ? wod.scalingOptions.first
              : ScalingLevel.none,
          unit: wod.scoreType == WodScoreType.distance ? 'm' : 'kg',
        ),
    };

    return MixedSessionState(
      workout: workout,
      setDrafts: Map.unmodifiable(setDrafts),
      wodDrafts: Map.unmodifiable(wodDrafts),
    );
  }

  void updateSetDraft(
    String key, {
    String? repsInput,
    String? weightInput,
    bool? completed,
    Object? rpe = _unset,
    String? notes,
  }) {
    final current = state.requireValue;
    final draft = current.setDrafts[key];
    if (draft == null) throw StateError('Unknown set.');

    final drafts = Map<String, SetResultDraft>.of(current.setDrafts);
    drafts[key] = draft.copyWith(
      repsInput: repsInput,
      weightInput: weightInput,
      completed: completed,
      rpe: identical(rpe, _unset) ? draft.rpe : rpe,
      notes: notes,
    );

    state = AsyncData(
      current.copyWith(setDrafts: Map.unmodifiable(drafts), clearError: true),
    );
  }

  void updateWodDraft(
    String wodId, {
    ScalingLevel? scaling,
    String? primaryInput,
    String? secondaryInput,
    String? unit,
    bool? dnf,
    Object? rpe = _unset,
    String? notes,
  }) {
    final current = state.requireValue;
    final draft = current.wodDrafts[wodId];
    if (draft == null) throw StateError('Unknown WOD.');

    final drafts = Map<String, WodResultDraft>.of(current.wodDrafts);
    drafts[wodId] = draft.copyWith(
      scaling: scaling,
      primaryInput: primaryInput,
      secondaryInput: secondaryInput,
      unit: unit,
      dnf: dnf,
      rpe: identical(rpe, _unset) ? draft.rpe : rpe,
      notes: notes,
    );

    state = AsyncData(
      current.copyWith(wodDrafts: Map.unmodifiable(drafts), clearError: true),
    );
  }

  Future<bool> submit() async {
    final current = state.requireValue;
    if (current.submitting || current.finished) return false;

    final setResults = <SetResult>[];
    for (final draft in current.setDrafts.values) {
      if (!draft.completed) continue;
      if (!draft.isValid) {
        state = AsyncData(
          current.copyWith(error: 'Fix invalid completed strength sets.'),
        );
        return false;
      }
      setResults.add(draft.toResult());
    }

    final wodResults = <WodResultEntry>[];
    for (final wod in current.workout.scoredWods) {
      final result = current.wodDrafts[wod.id]?.toResult(wod);
      if (result == null) {
        state = AsyncData(
          current.copyWith(error: 'Complete all required WOD score fields.'),
        );
        return false;
      }
      wodResults.add(result);
    }

    if (setResults.isEmpty) {
      state = AsyncData(
        current.copyWith(error: 'Complete at least one strength set.'),
      );
      return false;
    }

    state = AsyncData(current.copyWith(submitting: true, clearError: true));

    try {
      await ref.read(workoutRepositoryProvider).submitWorkoutResult(
            WorkoutResult(
              workoutId: workoutId,
              setResults: setResults,
              wodResults: wodResults,
              completedAt: DateTime.now(),
            ),
          );

      ref.invalidate(workoutHistoryProvider);
      ref.invalidate(progressSummaryProvider);
      ref.invalidate(workoutControllerProvider);
      ref.invalidate(workoutDetailProvider(workoutId));

      state = AsyncData(
        current.copyWith(
          submitting: false,
          finished: true,
          clearError: true,
        ),
      );
      return true;
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          submitting: false,
          finished: false,
          error: 'Could not save. Your session entries are still here.',
        ),
      );
      rethrow;
    }
  }

  String _targetWeightInput(ExerciseSet set) {
    final target = set.targetWeight;
    if (target == null) return '';
    return target == target.roundToDouble()
        ? target.round().toString()
        : target.toStringAsFixed(1);
  }

  static const _unset = Object();
}
