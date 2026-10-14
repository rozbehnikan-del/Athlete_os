import 'dart:convert';

import 'package:athlete_os/src/core/api/api_client.dart';
import 'package:athlete_os/src/core/api/api_config.dart';
import 'package:athlete_os/src/core/errors/app_exception.dart';
import 'package:athlete_os/src/features/training/application/workout_providers.dart';
import 'package:athlete_os/src/features/training/data/repositories/api_workout_repository.dart';
import 'package:athlete_os/src/features/training/data/repositories/mock_workout_repository.dart';
import 'package:athlete_os/src/features/training/domain/entities/exercise_set.dart';
import 'package:athlete_os/src/features/training/domain/entities/workout_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  ApiWorkoutRepository repositoryFor(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return ApiWorkoutRepository(
      ApiClient(
        config: const ApiConfig(baseUrl: 'http://api.test'),
        httpClient: MockClient(handler),
      ),
    );
  }

  http.Response jsonResponse(
    Map<String, dynamic> body, {
    int statusCode = 200,
  }) {
    return http.Response(
      jsonEncode(body),
      statusCode,
      headers: {'Content-Type': 'application/json'},
    );
  }

  group('ApiWorkoutRepository', () {
    test("today's workout JSON maps correctly", () async {
      final repository = repositoryFor(
        (_) async => jsonResponse(workoutEnvelope(id: 'today-workout')),
      );

      final workout = (await repository.getTodayWorkout('athlete-ali'))!;

      expect(workout.id, 'today-workout');
      expect(workout.title, "Today's Workout");
      expect(workout.category, 'Strength');
      expect(workout.focus, 'Lower Body');
      expect(workout.exercises.first.id, 'back-squat-prescription');
      expect(workout.exercises.first.exerciseId, 'back-squat-id');
      expect(workout.exercises.first.name, 'Back Squat');
      expect(workout.exercises.first.coachingNote, 'Stay braced.');
      expect(workout.exercises.first.sets.first.setNumber, 1);
      expect(
        workout.exercises.first.sets.first.id,
        'back-squat-prescription-set-1',
      );
      expect(workout.exercises.first.sets.first.targetReps, 8);
      expect(workout.exercises.first.sets.first.targetWeight, 80);
    });

    test('today API with null data returns no workout', () async {
      final repository = repositoryFor(
        (_) async => jsonResponse({'data': null}),
      );

      final workout = await repository.getTodayWorkout('athlete-ali');

      expect(workout, isNull);
    });

    test('nullable category and focus do not crash mapping', () async {
      final repository = repositoryFor(
        (_) async => jsonResponse(workoutEnvelope(category: null, focus: null)),
      );

      final workout = (await repository.getTodayWorkout('athlete-ali'))!;

      expect(workout.category, '');
      expect(workout.focus, '');
    });

    test('nullable target fields are mapped predictably', () async {
      final repository = repositoryFor(
        (_) async => jsonResponse(workoutEnvelope(nullableFirstSet: true)),
      );

      final workout = (await repository.getTodayWorkout('athlete-ali'))!;
      final set = workout.exercises.first.sets.first;

      expect(set.targetReps, isNull);
      expect(set.targetWeight, isNull);
      expect(set.weightUnit, isNull);
    });

    test('three exercises and expected set counts are parsed', () async {
      final repository = repositoryFor(
        (_) async => jsonResponse(workoutEnvelope()),
      );

      final workout = (await repository.getTodayWorkout('athlete-ali'))!;

      expect(workout.exercises, hasLength(3));
      expect(workout.exercises[0].name, 'Back Squat');
      expect(workout.exercises[0].sets, hasLength(4));
      expect(workout.exercises[1].name, 'Romanian Deadlift');
      expect(workout.exercises[1].sets, hasLength(3));
      expect(workout.exercises[2].name, 'Walking Lunges');
      expect(workout.exercises[2].sets, hasLength(3));
    });

    test('kg maps to WeightUnit.kg', () async {
      final repository = repositoryFor(
        (_) async => jsonResponse(workoutEnvelope()),
      );

      final workout = (await repository.getTodayWorkout('athlete-ali'))!;

      expect(workout.exercises.first.sets.first.weightUnit, WeightUnit.kg);
    });

    test('submitWorkoutResult posts correct JSON payload', () async {
      late Uri requestedUri;
      late Map<String, dynamic> requestedBody;
      final repository = repositoryFor((request) async {
        requestedUri = request.url;
        requestedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return jsonResponse({
          'data': {
            'id': 'result-1',
            'workout_id': 'workout-123',
            'status': 'completed',
            'completed_at': '2026-10-14T12:45:30Z',
            'completed_sets': 2,
            'notes': 'Done.',
          },
        }, statusCode: 201);
      });

      await repository.submitWorkoutResult(
        WorkoutResult(
          workoutId: 'workout-123',
          athleteId: 'athlete-ali',
          completedAt: DateTime.parse('2026-10-14T12:45:30+03:30'),
          notes: 'Done.',
          setResults: const [
            SetResult(
              setId: 'set-kg',
              prescriptionId: 'prescription-kg',
              exerciseId: 'exercise-kg',
              setNumber: 1,
              actualReps: 8,
              actualWeight: 82.5,
              weightUnit: WeightUnit.kg,
              completed: true,
              rpe: 8,
            ),
            SetResult(
              setId: 'set-lb',
              prescriptionId: 'prescription-lb',
              exerciseId: 'exercise-lb',
              setNumber: 2,
              actualReps: 7,
              actualWeight: 180,
              weightUnit: WeightUnit.lb,
              completed: true,
            ),
          ],
        ),
      );

      final sets = requestedBody['sets'] as List<dynamic>;
      final firstSet = sets.first as Map<String, dynamic>;
      final secondSet = sets.last as Map<String, dynamic>;

      expect(requestedUri.path, '/v1/workouts/workout-123/results');
      expect(firstSet['set_id'], 'set-kg');
      expect(firstSet['weight_unit'], 'kg');
      expect(secondSet['weight_unit'], 'lb');
      expect(requestedBody.containsKey('athlete_id'), isFalse);
      expect(firstSet.containsKey('prescription_id'), isFalse);
      expect(firstSet.containsKey('exercise_id'), isFalse);
      expect(firstSet.containsKey('set_number'), isFalse);
    });

    test('history endpoint and mapping are correct', () async {
      late Uri requestedUri;
      final repository = repositoryFor((request) async {
        requestedUri = request.url;
        return jsonResponse(historyEnvelope());
      });

      final history = await repository.getWorkoutHistory('athlete-ali');
      final entry = history.single;
      final firstSet = entry.setResults.first;
      final secondSet = entry.setResults.last;

      expect(requestedUri.path, '/v1/athletes/me/workout-history');
      expect(requestedUri.query, 'page=1&per_page=20');
      expect(entry.workoutId, 'workout-123');
      expect(entry.workoutTitle, "Today's Workout");
      expect(entry.completedAt, DateTime.parse('2026-10-14T12:45:30Z'));
      expect(entry.notes, 'Felt strong today.');
      expect(firstSet.setId, 'set-1');
      expect(firstSet.prescriptionId, 'prescription-1');
      expect(firstSet.exerciseId, 'exercise-1');
      expect(firstSet.rpe, 8);
      expect(secondSet.rpe, isNull);
    });

    test('history newest-first order remains unchanged', () async {
      final repository = repositoryFor(
        (_) async => jsonResponse(historyEnvelope(includeOlder: true)),
      );

      final history = await repository.getWorkoutHistory('athlete-ali');

      expect(history.map((entry) => entry.workoutId), [
        'workout-123',
        'workout-older',
      ]);
    });

    test('malformed history JSON throws RepositoryException', () async {
      final repository = repositoryFor(
        (_) async => jsonResponse({'data': 'not-a-list'}),
      );

      expect(
        repository.getWorkoutHistory('athlete-ali'),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('getWorkoutById uses correct path', () async {
      late Uri requestedUri;
      final repository = repositoryFor((request) async {
        requestedUri = request.url;
        return jsonResponse(workoutEnvelope(id: 'workout-123'));
      });

      final workout = await repository.getWorkoutById(
        athleteId: 'athlete-ali',
        workoutId: 'workout-123',
      );

      expect(requestedUri.path, '/v1/workouts/workout-123');
      expect(workout.id, 'workout-123');
    });

    test('404 maps to app exception', () async {
      final repository = repositoryFor(
        (_) async => jsonResponse({
          'error': {
            'code': 'WORKOUT_NOT_FOUND',
            'message': 'Workout not found.',
          },
        }, statusCode: 404),
      );

      expect(
        repository.getWorkoutById(
          athleteId: 'athlete-ali',
          workoutId: 'missing',
        ),
        throwsA(
          isA<RepositoryException>().having(
            (exception) => exception.message,
            'message',
            'Workout not found.',
          ),
        ),
      );
    });

    test('malformed JSON is handled safely', () async {
      final repository = repositoryFor(
        (_) async => http.Response('{not-json', 200),
      );

      expect(
        repository.getTodayWorkout('athlete-ali'),
        throwsA(isA<RepositoryException>()),
      );
    });

    test(
      'provider can still be overridden with MockWorkoutRepository',
      () async {
        final mockRepository = MockWorkoutRepository();
        final container = ProviderContainer(
          overrides: [
            workoutRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final repository = container.read(workoutRepositoryProvider);
        final workout = (await repository.getTodayWorkout('athlete-ali'))!;

        expect(identical(repository, mockRepository), isTrue);
        expect(workout.title, "Today's Workout");
      },
    );
  });
}

Map<String, dynamic> historyEnvelope({bool includeOlder = false}) {
  return {
    'data': [
      {
        'id': 'result-1',
        'workout_id': 'workout-123',
        'workout_title': "Today's Workout",
        'category': 'Strength',
        'focus': 'Lower Body',
        'completed_at': '2026-10-14T12:45:30Z',
        'completed_sets': 1,
        'total_sets': 2,
        'notes': 'Felt strong today.',
        'sets': [
          {
            'prescription_id': 'prescription-1',
            'exercise_id': 'exercise-1',
            'set_id': 'set-1',
            'set_number': 1,
            'actual_reps': 8,
            'actual_weight': 82.5,
            'weight_unit': 'kg',
            'rpe': 8.0,
            'completed': true,
            'notes': null,
          },
          {
            'prescription_id': 'prescription-2',
            'exercise_id': 'exercise-2',
            'set_id': 'set-2',
            'set_number': 2,
            'actual_reps': 7,
            'actual_weight': 80,
            'weight_unit': 'kg',
            'rpe': null,
            'completed': false,
            'notes': 'Skipped.',
          },
        ],
      },
      if (includeOlder)
        {
          'id': 'result-older',
          'workout_id': 'workout-older',
          'workout_title': 'Older Workout',
          'category': 'Strength',
          'focus': 'Upper Body',
          'completed_at': '2026-10-13T12:45:30Z',
          'completed_sets': 1,
          'total_sets': 1,
          'notes': null,
          'sets': [
            {
              'prescription_id': 'older-prescription',
              'exercise_id': 'older-exercise',
              'set_id': 'older-set',
              'set_number': 1,
              'actual_reps': 8,
              'actual_weight': 80,
              'weight_unit': 'kg',
              'rpe': null,
              'completed': true,
              'notes': null,
            },
          ],
        },
    ],
    'meta': {'page': 1, 'per_page': 20, 'total': includeOlder ? 2 : 1},
  };
}

Map<String, dynamic> workoutEnvelope({
  String id = 'today-workout',
  String? category = 'Strength',
  String? focus = 'Lower Body',
  bool nullableFirstSet = false,
}) {
  return {
    'data': {
      'id': id,
      'title': "Today's Workout",
      'category': category,
      'focus': focus,
      'scheduled_for': '2026-10-14',
      'status': 'active',
      'coach': {'id': 'coach-id', 'name': 'Demo Coach'},
      'exercises': [
        exerciseJson(
          prescriptionId: 'back-squat-prescription',
          exerciseId: 'back-squat-id',
          slug: 'back-squat',
          name: 'Back Squat',
          coachingNote: 'Stay braced.',
          setCount: 4,
          reps: 8,
          weight: 80,
          nullableFirstSet: nullableFirstSet,
        ),
        exerciseJson(
          prescriptionId: 'romanian-deadlift-prescription',
          exerciseId: 'romanian-deadlift-id',
          slug: 'romanian-deadlift',
          name: 'Romanian Deadlift',
          coachingNote: 'Keep the bar close.',
          setCount: 3,
          reps: 10,
          weight: 70,
        ),
        exerciseJson(
          prescriptionId: 'walking-lunges-prescription',
          exerciseId: 'walking-lunges-id',
          slug: 'walking-lunges',
          name: 'Walking Lunges',
          coachingNote: 'Tall posture.',
          setCount: 3,
          reps: 12,
          weight: 20,
        ),
      ],
    },
  };
}

Map<String, dynamic> exerciseJson({
  required String prescriptionId,
  required String exerciseId,
  required String slug,
  required String name,
  required String coachingNote,
  required int setCount,
  required int reps,
  required double weight,
  bool nullableFirstSet = false,
}) {
  return {
    'prescription_id': prescriptionId,
    'exercise': {'id': exerciseId, 'slug': slug, 'name': name},
    'order': 1,
    'coaching_note': coachingNote,
    'sets': [
      for (var index = 1; index <= setCount; index++)
        {
          'id': '$prescriptionId-set-$index',
          'set_number': index,
          'target_reps': nullableFirstSet && index == 1 ? null : reps,
          'target_weight': nullableFirstSet && index == 1 ? null : weight,
          'weight_unit': nullableFirstSet && index == 1 ? null : 'kg',
        },
    ],
  };
}
