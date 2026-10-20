import 'workout_result.dart';
import 'completion_grade.dart';

class WorkoutHistoryEntry {
  const WorkoutHistoryEntry({
    required this.workoutId,
    required this.workoutTitle,
    required this.completedAt,
    required this.setResults,
    this.notes,
    this.prescribedSets,
    this.recordedCompletedSets,
  });

  final String workoutId;
  final String workoutTitle;
  final DateTime completedAt;
  final List<SetResult> setResults;
  final String? notes;
  final int? prescribedSets;
  final int? recordedCompletedSets;
  int get completedSets =>
      recordedCompletedSets ?? setResults.where((s) => s.completed).length;
  int get totalSets => prescribedSets ?? setResults.length;
  CompletionGrade get completion =>
      CompletionGrade(completedSets: completedSets, totalSets: totalSets);
}
