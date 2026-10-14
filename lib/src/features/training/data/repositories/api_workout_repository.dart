import '../../../../core/api/api_client.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/exercise_prescription.dart';
import '../../domain/entities/exercise_set.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_history_entry.dart';
import '../../domain/entities/workout_result.dart';
import '../../domain/repositories/workout_repository.dart';

class ApiWorkoutRepository implements WorkoutRepository {
  ApiWorkoutRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Workout> getTodayWorkout(String athleteId) async {
    // TODO: Remove athleteId after JWT auth makes /athletes/me authoritative.
    final json = await _apiClient.get('/v1/athletes/me/workouts/today');
    return _workoutFromEnvelope(json);
  }

  @override
  Future<Workout> getWorkoutById({
    required String athleteId,
    required String workoutId,
  }) async {
    // TODO: Remove athleteId after JWT auth makes workout ownership server-side.
    final json = await _apiClient.get('/v1/workouts/$workoutId');
    return _workoutFromEnvelope(json);
  }

  @override
  Future<void> submitWorkoutResult(WorkoutResult result) async {
    throw const RepositoryException(
      'Workout result submission is not implemented for the API yet.',
    );
  }

  @override
  Future<List<WorkoutHistoryEntry>> getWorkoutHistory(String athleteId) async {
    throw const RepositoryException(
      'Workout history is not implemented for the API yet.',
    );
  }

  Workout _workoutFromEnvelope(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const RepositoryException('Server returned malformed workout data.');
    }

    final exercises = data['exercises'];
    if (exercises is! List) {
      throw const RepositoryException('Server returned malformed workout data.');
    }

    return Workout(
      id: _readString(data, 'id'),
      title: _readString(data, 'title'),
      category: _readString(data, 'category'),
      focus: _readString(data, 'focus'),
      exercises: exercises.map(_exerciseFromJson),
    );
  }

  ExercisePrescription _exerciseFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const RepositoryException('Server returned malformed exercise data.');
    }

    final exercise = value['exercise'];
    final sets = value['sets'];
    if (exercise is! Map<String, dynamic> || sets is! List) {
      throw const RepositoryException('Server returned malformed exercise data.');
    }

    return ExercisePrescription(
      id: _readString(value, 'prescription_id'),
      exerciseId: _readString(exercise, 'id'),
      name: _readString(exercise, 'name'),
      coachingNote: _readOptionalString(value, 'coaching_note'),
      sets: sets.map(_setFromJson),
    );
  }

  ExerciseSet _setFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const RepositoryException('Server returned malformed set data.');
    }

    return ExerciseSet(
      setNumber: _readInt(value, 'set_number'),
      targetReps: _readInt(value, 'target_reps'),
      targetWeight: _readDouble(value, 'target_weight'),
      weightUnit: _weightUnitFromJson(_readString(value, 'weight_unit')),
    );
  }

  WeightUnit _weightUnitFromJson(String value) {
    return switch (value.toLowerCase()) {
      'kg' => WeightUnit.kg,
      'lb' => WeightUnit.lb,
      _ => throw const RepositoryException(
        'Server returned an unsupported weight unit.',
      ),
    };
  }

  String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw const RepositoryException('Server returned malformed workout data.');
  }

  String? _readOptionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    throw const RepositoryException('Server returned malformed workout data.');
  }

  int _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    throw const RepositoryException('Server returned malformed workout data.');
  }

  double _readDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    throw const RepositoryException('Server returned malformed workout data.');
  }
}
