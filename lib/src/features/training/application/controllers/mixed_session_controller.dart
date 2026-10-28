import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../progress/application/progress_providers.dart';
import '../../domain/entities/crossfit.dart';
import '../../domain/entities/exercise_set.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_result.dart';
import '../drafts/mixed_session_draft_store.dart';
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
    this.currentBlockIndex = 0,
    this.completedBlockIds = const <String>{},
    this.submitting = false,
    this.finished = false,
    this.error,
  });

  final Workout workout;
  final Map<String, SetResultDraft> setDrafts;
  final Map<String, WodResultDraft> wodDrafts;
  final int currentBlockIndex;
  final Set<String> completedBlockIds;
  final bool submitting;
  final bool finished;
  final String? error;

  List<TrainingBlock> get blocks => workout.session!.blocks;
  TrainingBlock get currentBlock => blocks[currentBlockIndex];
  bool get isFirstBlock => currentBlockIndex == 0;
  bool get isLastBlock => currentBlockIndex == blocks.length - 1;

  int get totalSets => setDrafts.length;
  int get completedSets =>
      setDrafts.values.where((draft) => draft.completed).length;

  double get progress =>
      blocks.isEmpty ? 0 : completedBlockIds.length / blocks.length;

  MixedSessionState copyWith({
    Map<String, SetResultDraft>? setDrafts,
    Map<String, WodResultDraft>? wodDrafts,
    int? currentBlockIndex,
    Set<String>? completedBlockIds,
    bool? submitting,
    bool? finished,
    String? error,
    bool clearError = false,
  }) {
    return MixedSessionState(
      workout: workout,
      setDrafts: setDrafts ?? this.setDrafts,
      wodDrafts: wodDrafts ?? this.wodDrafts,
      currentBlockIndex: currentBlockIndex ?? this.currentBlockIndex,
      completedBlockIds: completedBlockIds ?? this.completedBlockIds,
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

    Map<String, dynamic>? stored;
    try {
      stored = await ref.read(mixedSessionDraftStoreProvider).load(workoutId);
    } catch (_) {
      // Storage is best-effort; never prevent an athlete from training.
    }
    final snapshot = MixedSessionDraftSnapshot.restore(
      stored,
      defaultSets: setDrafts,
      defaultWods: wodDrafts,
      blockIds: [for (final block in workout.session!.blocks) block.id],
    );
    return MixedSessionState(
      workout: workout,
      setDrafts: snapshot.setDrafts,
      wodDrafts: snapshot.wodDrafts,
      currentBlockIndex: snapshot.currentBlockIndex,
      completedBlockIds: snapshot.completedBlockIds,
    );
  }

  void _persist(MixedSessionState current) {
    unawaited(_persistSafely(current));
  }

  Future<void> _persistSafely(MixedSessionState current) async {
    try {
      await ref.read(mixedSessionDraftStoreProvider).save(
        workoutId,
        MixedSessionDraftSnapshot(
          currentBlockIndex: current.currentBlockIndex,
          completedBlockIds: current.completedBlockIds,
          setDrafts: current.setDrafts,
          wodDrafts: current.wodDrafts,
        ).toJson(),
      );
    } catch (_) {
      // Keep active session usable if device storage is unavailable.
    }
  }

  void previousBlock() {
    final current = state.requireValue;
    if (current.isFirstBlock) return;
    final updated = current.copyWith(
      currentBlockIndex: current.currentBlockIndex - 1,
      clearError: true,
    );
    state = AsyncData(updated);
    _persist(updated);
  }

  bool completeCurrentBlockAndContinue() {
    final current = state.requireValue;
    final block = current.currentBlock;

    if (block.wod != null) {
      final wod = block.wod!;
      final result = current.wodDrafts[wod.id]?.toResult(wod);
      if (result == null) {
        state = AsyncData(
          current.copyWith(
            error: 'Enter a valid score before completing this WOD block.',
          ),
        );
        return false;
      }
    }

    final completed = Set<String>.of(current.completedBlockIds)..add(block.id);
    final nextIndex = current.isLastBlock
        ? current.currentBlockIndex
        : current.currentBlockIndex + 1;

    final updated = current.copyWith(
      currentBlockIndex: nextIndex,
      completedBlockIds: Set.unmodifiable(completed),
      clearError: true,
    );
    state = AsyncData(updated);
    _persist(updated);
    return true;
  }

  void goToBlock(int index) {
    final current = state.requireValue;
    if (index < 0 || index >= current.blocks.length) return;
    final updated = current.copyWith(
      currentBlockIndex: index,
      clearError: true,
    );
    state = AsyncData(updated);
    _persist(updated);
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

    final updated = current.copyWith(
      setDrafts: Map.unmodifiable(drafts),
      clearError: true,
    );
    state = AsyncData(updated);
    _persist(updated);
  }

  void updateWodDraft(
    String wodId, {
    ScalingLevel? scaling,
    String? primaryInput,
    String? secondaryInput,
    List<LoadAttemptDraft>? loadAttempts,
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
      loadAttempts: loadAttempts,
      unit: unit,
      dnf: dnf,
      rpe: identical(rpe, _unset) ? draft.rpe : rpe,
      notes: notes,
    );

    final updated = current.copyWith(
      wodDrafts: Map.unmodifiable(drafts),
      clearError: true,
    );
    state = AsyncData(updated);
    _persist(updated);
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

      try {
        await ref.read(mixedSessionDraftStoreProvider).clear(workoutId);
      } catch (_) {
        // Remote completion succeeded even if removing the cache failed.
      }

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
