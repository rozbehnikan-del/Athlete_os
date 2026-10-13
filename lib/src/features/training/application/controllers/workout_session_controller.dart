import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/exercise_prescription.dart';
import '../../domain/entities/exercise_set.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_result.dart';
import '../workout_providers.dart';
import 'workout_controller.dart';

final workoutSessionControllerProvider =
    AsyncNotifierProvider.family<
      WorkoutSessionController,
      WorkoutSessionState,
      String
    >(WorkoutSessionController.new);

class SetResultDraft {
  const SetResultDraft({
    required this.exerciseId,
    required this.setNumber,
    required this.actualReps,
    required this.actualWeight,
    required this.weightUnit,
    this.completed = false,
    this.rpe,
    this.notes,
  });

  final String exerciseId;
  final int setNumber;
  final int actualReps;
  final double actualWeight;
  final WeightUnit weightUnit;
  final bool completed;
  final double? rpe;
  final String? notes;

  SetResultDraft copyWith({
    int? actualReps,
    double? actualWeight,
    bool? completed,
    double? rpe,
    String? notes,
  }) {
    return SetResultDraft(
      exerciseId: exerciseId,
      setNumber: setNumber,
      actualReps: actualReps ?? this.actualReps,
      actualWeight: actualWeight ?? this.actualWeight,
      weightUnit: weightUnit,
      completed: completed ?? this.completed,
      rpe: rpe ?? this.rpe,
      notes: notes ?? this.notes,
    );
  }

  SetResult toResult() => SetResult(
    exerciseId: exerciseId,
    setNumber: setNumber,
    actualReps: actualReps,
    actualWeight: actualWeight,
    weightUnit: weightUnit,
    completed: completed,
    rpe: rpe,
    notes: notes,
  );
}

class WorkoutSessionState {
  WorkoutSessionState({
    required this.workout,
    required this.currentExerciseIndex,
    required this.currentSetIndex,
    required Map<String, SetResultDraft> drafts,
    this.workoutNote = '',
    this.submitting = false,
    this.finished = false,
  }) : drafts = Map.unmodifiable(drafts);

  final Workout workout;
  final int currentExerciseIndex;
  final int currentSetIndex;
  final Map<String, SetResultDraft> drafts;
  final String workoutNote;
  final bool submitting;
  final bool finished;

  ExercisePrescription get currentExercise =>
      workout.exercises[currentExerciseIndex];
  ExerciseSet get currentSet => currentExercise.sets[currentSetIndex];
  String get currentDraftKey =>
      draftKey(currentExercise.exerciseId, currentSet.setNumber);
  SetResultDraft get currentDraft => drafts[currentDraftKey]!;
  int get totalSets => workout.exercises.fold(
    0,
    (count, exercise) => count + exercise.sets.length,
  );
  int get completedSets =>
      drafts.values.where((draft) => draft.completed).length;
  bool get isLastSet =>
      currentExerciseIndex == workout.exercises.length - 1 &&
      currentSetIndex == currentExercise.sets.length - 1;
  double get progress => totalSets == 0 ? 0 : completedSets / totalSets;

  WorkoutSessionState copyWith({
    int? currentExerciseIndex,
    int? currentSetIndex,
    Map<String, SetResultDraft>? drafts,
    String? workoutNote,
    bool? submitting,
    bool? finished,
  }) {
    return WorkoutSessionState(
      workout: workout,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      drafts: drafts ?? this.drafts,
      workoutNote: workoutNote ?? this.workoutNote,
      submitting: submitting ?? this.submitting,
      finished: finished ?? this.finished,
    );
  }

  WorkoutResult buildResult({
    required String athleteId,
    required DateTime completedAt,
  }) {
    final results = drafts.values
        .where((draft) => draft.completed)
        .map((draft) => draft.toResult())
        .toList(growable: false);
    if (results.isEmpty) {
      throw StateError(
        'Complete at least one set before finishing the workout.',
      );
    }
    return WorkoutResult(
      workoutId: workout.id,
      athleteId: athleteId,
      setResults: results,
      completedAt: completedAt,
      notes: workoutNote.trim().isEmpty ? null : workoutNote.trim(),
    );
  }
}

String draftKey(String exerciseId, int setNumber) => '$exerciseId:$setNumber';

class WorkoutSessionController extends AsyncNotifier<WorkoutSessionState> {
  WorkoutSessionController(this.workoutId);

  final String workoutId;

  @override
  Future<WorkoutSessionState> build() async {
    final workout = await ref
        .watch(workoutRepositoryProvider)
        .getWorkoutById(
          athleteId: WorkoutController.athleteId,
          workoutId: workoutId,
        );
    final drafts = <String, SetResultDraft>{};
    for (final exercise in workout.exercises) {
      for (final set in exercise.sets) {
        drafts[draftKey(exercise.exerciseId, set.setNumber)] = SetResultDraft(
          exerciseId: exercise.exerciseId,
          setNumber: set.setNumber,
          actualReps: set.targetReps,
          actualWeight: set.targetWeight,
          weightUnit: set.weightUnit,
        );
      }
    }
    return WorkoutSessionState(
      workout: workout,
      currentExerciseIndex: 0,
      currentSetIndex: 0,
      drafts: drafts,
    );
  }

  void updateActualReps(int reps) {
    if (reps < 0) {
      throw ArgumentError.value(
        reps,
        'reps',
        'Actual reps must be at least 0.',
      );
    }
    _updateCurrentDraft((draft) => draft.copyWith(actualReps: reps));
  }

  void updateActualWeight(double weight) {
    if (weight < 0) {
      throw ArgumentError.value(
        weight,
        'weight',
        'Actual weight must be at least 0.',
      );
    }
    _updateCurrentDraft((draft) => draft.copyWith(actualWeight: weight));
  }

  void updateRpe(double? rpe) {
    if (rpe != null && (rpe < 1 || rpe > 10)) {
      throw ArgumentError.value(rpe, 'rpe', 'RPE must be between 1 and 10.');
    }
    _updateCurrentDraft((draft) => draft.copyWith(rpe: rpe));
  }

  void updateWorkoutNote(String note) {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(workoutNote: note));
  }

  void completeCurrentSet() {
    _updateCurrentDraft((draft) => draft.copyWith(completed: true));
    final current = state.requireValue;
    if (!current.isLastSet) {
      nextSet();
    }
  }

  void nextSet() {
    final current = state.requireValue;
    if (current.currentSetIndex < current.currentExercise.sets.length - 1) {
      state = AsyncData(
        current.copyWith(currentSetIndex: current.currentSetIndex + 1),
      );
      return;
    }
    if (current.currentExerciseIndex < current.workout.exercises.length - 1) {
      state = AsyncData(
        current.copyWith(
          currentExerciseIndex: current.currentExerciseIndex + 1,
          currentSetIndex: 0,
        ),
      );
    }
  }

  void previousSet() {
    final current = state.requireValue;
    if (current.currentSetIndex > 0) {
      state = AsyncData(
        current.copyWith(currentSetIndex: current.currentSetIndex - 1),
      );
      return;
    }
    if (current.currentExerciseIndex > 0) {
      final previousExercise =
          current.workout.exercises[current.currentExerciseIndex - 1];
      state = AsyncData(
        current.copyWith(
          currentExerciseIndex: current.currentExerciseIndex - 1,
          currentSetIndex: previousExercise.sets.length - 1,
        ),
      );
    }
  }

  Future<void> finishWorkout() async {
    final current = state.requireValue;
    final result = current.buildResult(
      athleteId: WorkoutController.athleteId,
      completedAt: DateTime.now(),
    );
    state = AsyncData(current.copyWith(submitting: true));
    await ref.read(workoutRepositoryProvider).submitWorkoutResult(result);
    ref.invalidate(workoutHistoryProvider);
    state = AsyncData(current.copyWith(submitting: false, finished: true));
  }

  void _updateCurrentDraft(
    SetResultDraft Function(SetResultDraft draft) update,
  ) {
    final current = state.requireValue;
    final drafts = Map<String, SetResultDraft>.of(current.drafts);
    drafts[current.currentDraftKey] = update(current.currentDraft);
    state = AsyncData(current.copyWith(drafts: drafts));
  }
}
