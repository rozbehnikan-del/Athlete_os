import 'exercise_set.dart';

class SetResult {
  const SetResult({
    required this.setId,
    required this.prescriptionId,
    required this.exerciseId,
    required this.setNumber,
    required this.actualReps,
    required this.actualWeight,
    required this.weightUnit,
    required this.completed,
    this.rpe,
    this.notes,
  });

  final String setId;
  final String prescriptionId;
  final String exerciseId;
  final int setNumber;
  final int actualReps;
  final double actualWeight;
  final WeightUnit weightUnit;
  final bool completed;
  final double? rpe;
  final String? notes;
}

class WorkoutResult {
  const WorkoutResult({
    required this.workoutId,
    required this.setResults,
    required this.completedAt,
    this.notes,
  });

  final String workoutId;
  final List<SetResult> setResults;
  final DateTime completedAt;
  final String? notes;
}
