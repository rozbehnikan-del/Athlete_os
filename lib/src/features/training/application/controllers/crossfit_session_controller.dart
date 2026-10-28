import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../progress/application/progress_providers.dart';
import '../../domain/entities/crossfit.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_result.dart';
import '../workout_providers.dart';
import 'workout_controller.dart';

final workoutDetailProvider = FutureProvider.family<Workout, String>(
  (ref, workoutId) => ref
      .watch(workoutRepositoryProvider)
      .getWorkoutById(workoutId: workoutId),
);

final crossFitSessionControllerProvider = AsyncNotifierProvider.family<
    CrossFitSessionController,
    CrossFitSessionState,
    String>(CrossFitSessionController.new);

class LoadAttemptDraft {
  const LoadAttemptDraft({
    required this.id,
    this.loadInput = '',
    this.successful = true,
  });

  final String id;
  final String loadInput;
  final bool successful;

  LoadAttemptDraft copyWith({String? loadInput, bool? successful}) =>
      LoadAttemptDraft(
        id: id,
        loadInput: loadInput ?? this.loadInput,
        successful: successful ?? this.successful,
      );
}

class WodResultDraft {
  const WodResultDraft({
    required this.wodId,
    required this.scaling,
    this.primaryInput = '',
    this.secondaryInput = '',
    this.loadAttempts = const [],
    this.unit = 'kg',
    this.dnf = false,
    this.rpe,
    this.notes = '',
  });

  final String wodId;
  final ScalingLevel scaling;
  final String primaryInput;
  final String secondaryInput;
  final List<LoadAttemptDraft> loadAttempts;
  final String unit;
  final bool dnf;
  final double? rpe;
  final String notes;

  WodResultDraft copyWith({
    ScalingLevel? scaling,
    String? primaryInput,
    String? secondaryInput,
    List<LoadAttemptDraft>? loadAttempts,
    String? unit,
    bool? dnf,
    Object? rpe = _unset,
    String? notes,
  }) {
    return WodResultDraft(
      wodId: wodId,
      scaling: scaling ?? this.scaling,
      primaryInput: primaryInput ?? this.primaryInput,
      secondaryInput: secondaryInput ?? this.secondaryInput,
      loadAttempts: loadAttempts ?? this.loadAttempts,
      unit: unit ?? this.unit,
      dnf: dnf ?? this.dnf,
      rpe: identical(rpe, _unset) ? this.rpe : rpe as double?,
      notes: notes ?? this.notes,
    );
  }

  WodScore? scoreFor(WodDefinition wod) {
    switch (wod.scoreType) {
      case WodScoreType.time:
        final seconds = _parseTime(primaryInput);
        return seconds != null && seconds > 0 ? TimeWodScore(seconds) : null;
      case WodScoreType.roundsReps:
        final rounds = int.tryParse(primaryInput);
        final reps = int.tryParse(secondaryInput);
        return rounds != null && rounds >= 0 && reps != null && reps >= 0
            ? RoundsRepsWodScore(rounds: rounds, reps: reps)
            : null;
      case WodScoreType.load:
        if (unit != 'kg' && unit != 'lb') return null;
        if (loadAttempts.isNotEmpty) {
          if (loadAttempts.length > 30) return null;
          final parsed = <LoadAttempt>[];
          for (final draft in loadAttempts) {
            final load = double.tryParse(draft.loadInput);
            if (load == null || !load.isFinite || load <= 0) return null;
            parsed.add(LoadAttempt(load: load, successful: draft.successful));
          }
          final successful = parsed.where((attempt) => attempt.successful);
          if (successful.isEmpty) return null;
          final best = successful
              .map((attempt) => attempt.load)
              .reduce((a, b) => a > b ? a : b);
          return LoadWodScore(load: best, unit: unit, attempts: parsed);
        }
        final load = double.tryParse(primaryInput);
        return load != null && load.isFinite && load > 0
            ? LoadWodScore(load: load, unit: unit)
            : null;
      case WodScoreType.reps:
        final reps = int.tryParse(primaryInput);
        return reps != null && reps >= 0 ? RepsWodScore(reps) : null;
      case WodScoreType.calories:
        final calories = int.tryParse(primaryInput);
        return calories != null && calories >= 0
            ? CaloriesWodScore(calories)
            : null;
      case WodScoreType.distance:
        final distance = double.tryParse(primaryInput);
        return distance != null &&
                distance > 0 &&
                const {'m', 'km', 'mi'}.contains(unit)
            ? DistanceWodScore(distance: distance, unit: unit)
            : null;
      case WodScoreType.intervals:
        final values = primaryInput
            .split(',')
            .map((value) => double.tryParse(value.trim()))
            .toList();
        if (values.isEmpty || values.any((value) => value == null)) {
          return null;
        }
        final parsed = values.cast<double>();
        final targets = wod.scoreConfig['minute_targets'];
        if (wod.format == WodFormat.emom && targets is List) {
          if (parsed.length != targets.length ||
              parsed.any((value) =>
                  !value.isFinite ||
                  value < 0 ||
                  value != value.roundToDouble())) {
            return null;
          }
        }
        return IntervalsWodScore(parsed);
      case WodScoreType.none:
        return const NoWodScore();
    }
  }

  WodResultEntry? toResult(WodDefinition wod) {
    final score = scoreFor(wod);
    if (score == null || (rpe != null && (rpe! < 1 || rpe! > 10))) {
      return null;
    }
    return WodResultEntry(
      wodId: wodId,
      scaling: scaling,
      score: score,
      dnf: dnf,
      rpe: rpe,
      notes: notes.trim().isEmpty ? null : notes.trim(),
    );
  }

  static int? _parseTime(String input) {
    final trimmed = input.trim();
    final direct = int.tryParse(trimmed);
    if (direct != null) return direct;
    final parts = trimmed.split(':');
    if (parts.length != 2) return null;
    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);
    if (minutes == null || seconds == null || minutes < 0 || seconds < 0 || seconds > 59) {
      return null;
    }
    return minutes * 60 + seconds;
  }

  static const _unset = Object();
}

class CrossFitSessionState {
  const CrossFitSessionState({
    required this.workout,
    required this.drafts,
    this.submitting = false,
    this.finished = false,
    this.error,
  });

  final Workout workout;
  final Map<String, WodResultDraft> drafts;
  final bool submitting;
  final bool finished;
  final String? error;

  List<WodDefinition> get wods => workout.scoredWods;

  CrossFitSessionState copyWith({
    Map<String, WodResultDraft>? drafts,
    bool? submitting,
    bool? finished,
    String? error,
    bool clearError = false,
  }) {
    return CrossFitSessionState(
      workout: workout,
      drafts: drafts ?? this.drafts,
      submitting: submitting ?? this.submitting,
      finished: finished ?? this.finished,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class CrossFitSessionController extends AsyncNotifier<CrossFitSessionState> {
  CrossFitSessionController(this.workoutId);

  final String workoutId;

  @override
  Future<CrossFitSessionState> build() async {
    final workout = await ref
        .watch(workoutRepositoryProvider)
        .getWorkoutById(workoutId: workoutId);
    if (!workout.isWodOnly) {
      throw StateError(
        'CrossFit score entry currently requires a WOD-only session.',
      );
    }
    final drafts = <String, WodResultDraft>{
      for (final wod in workout.scoredWods)
        wod.id: WodResultDraft(
          wodId: wod.id,
          scaling: wod.scalingOptions.isNotEmpty
              ? wod.scalingOptions.first
              : ScalingLevel.none,
          unit: switch (wod.scoreType) {
            WodScoreType.distance => 'm',
            _ => 'kg',
          },
        ),
    };
    return CrossFitSessionState(workout: workout, drafts: drafts);
  }

  void updateDraft(
    String wodId, {
    ScalingLevel? scaling,
    String? primaryInput,
    String? secondaryInput,
    List<LoadAttemptDraft>? loadAttempts,
    String? unit,
    bool? dnf,
    Object? rpe = WodResultDraft._unset,
    String? notes,
  }) {
    final current = state.requireValue;
    final draft = current.drafts[wodId];
    if (draft == null) throw StateError('Unknown WOD.');
    final drafts = Map<String, WodResultDraft>.of(current.drafts);
    drafts[wodId] = draft.copyWith(
      scaling: scaling,
      primaryInput: primaryInput,
      secondaryInput: secondaryInput,
      loadAttempts: loadAttempts,
      unit: unit,
      dnf: dnf,
      rpe: rpe,
      notes: notes,
    );
    state = AsyncData(current.copyWith(drafts: drafts, clearError: true));
  }

  Future<bool> submit() async {
    final current = state.requireValue;
    if (current.submitting || current.finished) return false;

    final results = <WodResultEntry>[];
    for (final wod in current.wods) {
      final result = current.drafts[wod.id]?.toResult(wod);
      if (result == null) {
        state = AsyncData(
          current.copyWith(error: 'Complete all required WOD score fields.'),
        );
        return false;
      }
      results.add(result);
    }

    state = AsyncData(current.copyWith(submitting: true, clearError: true));
    try {
      await ref.read(workoutRepositoryProvider).submitWorkoutResult(
            WorkoutResult(
              workoutId: workoutId,
              wodResults: results,
              completedAt: DateTime.now(),
            ),
          );
      ref.invalidate(workoutHistoryProvider);
      ref.invalidate(progressSummaryProvider);
      ref.invalidate(workoutControllerProvider);
      ref.invalidate(workoutDetailProvider(workoutId));
      state = AsyncData(
        current.copyWith(submitting: false, finished: true, clearError: true),
      );
      return true;
    } catch (_) {
      state = AsyncData(
        current.copyWith(
          submitting: false,
          finished: false,
          error: 'Could not save result. Your entries are still here.',
        ),
      );
      rethrow;
    }
  }
}
