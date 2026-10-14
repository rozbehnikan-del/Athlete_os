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
  Future<Workout?> getTodayWorkout(String athleteId) async {
    // TODO: Remove athleteId after JWT auth makes /athletes/me authoritative.
    final json = await _apiClient.get('/v1/athletes/me/workouts/today');
    return _nullableWorkoutFromEnvelope(json);
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
    await _apiClient.post(
      '/v1/workouts/${result.workoutId}/results',
      body: {
        'completed_at': result.completedAt.toUtc().toIso8601String(),
        'notes': result.notes,
        'sets': [
          for (final setResult in result.setResults)
            {
              'set_id': setResult.setId,
              'actual_reps': setResult.actualReps,
              'actual_weight': setResult.actualWeight,
              'weight_unit': _weightUnitToJson(setResult.weightUnit),
              'rpe': setResult.rpe,
              'completed': setResult.completed,
              'notes': setResult.notes,
            },
        ],
      },
    );
  }

  @override
  Future<List<WorkoutHistoryEntry>> getWorkoutHistory(String athleteId) async {
    // TODO: Remove athleteId after JWT auth makes /athletes/me authoritative.
    final json = await _apiClient.get(
      '/v1/athletes/me/workout-history?page=1&per_page=20',
    );
    return _historyFromEnvelope(json);
  }

  Workout _workoutFromEnvelope(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const RepositoryException(
        'Server returned malformed workout data.',
      );
    }

    final exercises = data['exercises'];
    if (exercises is! List) {
      throw const RepositoryException(
        'Server returned malformed workout data.',
      );
    }

    return Workout(
      id: _readString(data, 'id'),
      title: _readString(data, 'title'),
      category: _readOptionalString(data, 'category') ?? '',
      focus: _readOptionalString(data, 'focus') ?? '',
      exercises: exercises.map(_exerciseFromJson),
    );
  }

  Workout? _nullableWorkoutFromEnvelope(Map<String, dynamic> json) {
    if (json['data'] == null) {
      return null;
    }
    return _workoutFromEnvelope(json);
  }

  ExercisePrescription _exerciseFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const RepositoryException(
        'Server returned malformed exercise data.',
      );
    }

    final exercise = value['exercise'];
    final sets = value['sets'];
    if (exercise is! Map<String, dynamic> || sets is! List) {
      throw const RepositoryException(
        'Server returned malformed exercise data.',
      );
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
      id: _readString(value, 'id'),
      setNumber: _readInt(value, 'set_number'),
      targetReps: _readOptionalInt(value, 'target_reps'),
      targetWeight: _readOptionalDouble(value, 'target_weight'),
      weightUnit: _readOptionalWeightUnit(value, 'weight_unit'),
    );
  }

  List<WorkoutHistoryEntry> _historyFromEnvelope(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! List) {
      throw const RepositoryException(
        'Server returned malformed history data.',
      );
    }
    return data.map(_historyEntryFromJson).toList(growable: false);
  }

  WorkoutHistoryEntry _historyEntryFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const RepositoryException(
        'Server returned malformed history data.',
      );
    }
    final sets = value['sets'];
    if (sets is! List) {
      throw const RepositoryException(
        'Server returned malformed history data.',
      );
    }
    return WorkoutHistoryEntry(
      workoutId: _readString(value, 'workout_id'),
      workoutTitle: _readString(value, 'workout_title'),
      completedAt: _readDateTime(value, 'completed_at'),
      setResults: sets.map(_historySetFromJson).toList(growable: false),
      notes: _readOptionalString(value, 'notes'),
    );
  }

  SetResult _historySetFromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const RepositoryException(
        'Server returned malformed history data.',
      );
    }
    return SetResult(
      setId: _readString(value, 'set_id'),
      prescriptionId: _readString(value, 'prescription_id'),
      exerciseId: _readString(value, 'exercise_id'),
      setNumber: _readInt(value, 'set_number'),
      actualReps: _readInt(value, 'actual_reps'),
      actualWeight: _readDouble(value, 'actual_weight'),
      weightUnit: _weightUnitFromJson(_readString(value, 'weight_unit')),
      completed: _readBool(value, 'completed'),
      rpe: _readOptionalDouble(value, 'rpe'),
      notes: _readOptionalString(value, 'notes'),
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

  WeightUnit? _readOptionalWeightUnit(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is String) {
      return _weightUnitFromJson(value);
    }
    throw const RepositoryException('Server returned malformed workout data.');
  }

  String _weightUnitToJson(WeightUnit value) {
    return switch (value) {
      WeightUnit.kg => 'kg',
      WeightUnit.lb => 'lb',
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

  int? _readOptionalInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
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

  double? _readOptionalDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    throw const RepositoryException('Server returned malformed history data.');
  }

  bool _readBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    throw const RepositoryException('Server returned malformed history data.');
  }

  DateTime _readDateTime(Map<String, dynamic> json, String key) {
    try {
      return DateTime.parse(_readString(json, key));
    } on FormatException {
      throw const RepositoryException(
        'Server returned malformed history data.',
      );
    }
  }
}
