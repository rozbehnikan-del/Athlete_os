import '../../../core/api/api_client.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/coach_models.dart';
import '../domain/coach_repository.dart';

class ApiCoachRepository implements CoachRepository {
  ApiCoachRepository(this.client);
  final ApiClient client;

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on TypeError {
      throw const RepositoryException('Server returned malformed coach data.');
    } on FormatException {
      throw const RepositoryException('Server returned malformed coach data.');
    }
  }

  CoachAthlete _athlete(Map<String, dynamic> data) => CoachAthlete(
    id: data['id'] as String,
    name: data['full_name'] as String,
    email: data['email'] as String?,
    profile: (data['profile'] as Map<String, dynamic>?) ?? const {},
  );

  @override
  Future<List<CoachAthlete>> getAthletes() async {
    final json = await client.get('/v1/coaches/me/athletes');
    return _parse(
      () => (json['data'] as List)
          .map((e) => _athlete(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Future<AthleteTrainingDetail> getAthlete(String id) async {
    final json = await client.get('/v1/coaches/me/athletes/$id');
    return _parse(() {
      final data = json['data'] as Map<String, dynamic>;
      final training = data['training'] as Map<String, dynamic>;
      return AthleteTrainingDetail(
        athlete: _athlete(data),
        activeWorkout: training['active_workout'] as Map<String, dynamic>?,
        recentWorkouts: (training['recent_workouts'] as List)
            .cast<Map<String, dynamic>>(),
      );
    });
  }

  @override
  Future<List<LibraryExercise>> getExercises() async {
    final json = await client.get('/v1/exercises');
    return _parse(
      () => (json['data'] as List)
          .map(
            (e) => LibraryExercise(
              id: e['id'] as String,
              slug: e['slug'] as String,
              name: e['name'] as String,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<String> assign(String athleteId, WorkoutAssignment workout) async {
    final json = await client.post(
      '/v1/coaches/me/athletes/$athleteId/workouts',
      body: workout.toJson(),
    );
    return _parse(() => (json['data'] as Map<String, dynamic>)['id'] as String);
  }
}
