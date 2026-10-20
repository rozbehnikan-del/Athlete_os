import '../../training/domain/entities/completion_grade.dart';
import '../../training/domain/entities/workout_history_entry.dart';

class ProgressMetrics {
  ProgressMetrics(this.history);
  final List<WorkoutHistoryEntry> history;
  int get totalWorkouts => history.length;
  int get completedSets => history.fold(0, (n, w) => n + w.completedSets);
  int get prescribedSets => history.fold(0, (n, w) => n + w.totalSets);
  CompletionGrade get completion =>
      CompletionGrade(completedSets: completedSets, totalSets: prescribedSets);
  double? get recentChange {
    final graded = history.where((w) => w.totalSets > 0).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    if (graded.length < 6) return null;
    double percentage(Iterable<WorkoutHistoryEntry> entries) =>
        ProgressMetrics(entries.toList()).completion.percentage!;
    return percentage(graded.take(3)) - percentage(graded.skip(3).take(3));
  }
}
