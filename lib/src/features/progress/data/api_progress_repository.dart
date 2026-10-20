import '../../../core/api/api_client.dart';
import '../../../core/errors/app_exception.dart';
import '../../training/domain/entities/workout_history_entry.dart';
import '../domain/progress_repository.dart';
import '../domain/progress_summary.dart';

class ApiProgressRepository implements ProgressRepository {
  ApiProgressRepository(this.client);
  final ApiClient client;
  @override
  Future<ProgressSummary> getSummary() async {
    final envelope = await client.get('/v1/athletes/me/progress-summary');
    try {
      final data = envelope['data'] as Map<String, dynamic>;
      return ProgressSummary(
        totalWorkouts: data['total_completed_workouts'] as int,
        completedSets: data['total_completed_sets'] as int,
        prescribedSets: data['total_prescribed_sets'] as int,
        recentActivity: (data['recent_activity'] as List)
            .map((value) {
              final row = value as Map<String, dynamic>;
              return WorkoutHistoryEntry(
                workoutId: row['workout_id'] as String,
                workoutTitle: row['workout_title'] as String,
                completedAt: DateTime.parse(row['completed_at'] as String),
                prescribedSets: row['total_sets'] as int,
                recordedCompletedSets: row['completed_sets'] as int,
                setResults: const [],
              );
            })
            .toList(growable: false),
      );
    } on TypeError {
      throw const RepositoryException(
        'Server returned malformed progress data.',
      );
    } on FormatException {
      throw const RepositoryException(
        'Server returned malformed progress data.',
      );
    }
  }
}
