import '../../training/domain/entities/completion_grade.dart';
import '../../training/domain/entities/workout_history_entry.dart';

class ProgressSummary {
  const ProgressSummary({
    required this.totalWorkouts,
    required this.completedSets,
    required this.prescribedSets,
    required this.recentActivity,
  });
  final int totalWorkouts;
  final int completedSets;
  final int prescribedSets;
  final List<WorkoutHistoryEntry> recentActivity;
  CompletionGrade get completion =>
      CompletionGrade(completedSets: completedSets, totalSets: prescribedSets);
}
