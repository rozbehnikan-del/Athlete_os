import 'workout_result.dart';

class WorkoutHistoryEntry {
  const WorkoutHistoryEntry({
    required this.workoutId,
    required this.workoutTitle,
    required this.completedAt,
    required this.setResults,
    this.notes,
  });

  final String workoutId;
  final String workoutTitle;
  final DateTime completedAt;
  final List<SetResult> setResults;
  final String? notes;
}
