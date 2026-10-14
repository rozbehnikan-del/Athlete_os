import 'dart:convert';

import 'package:athlete_os/src/core/api/api_client.dart';
import 'package:athlete_os/src/core/api/api_config.dart';
import 'package:athlete_os/src/core/errors/app_exception.dart';
import 'package:athlete_os/src/features/training/application/workout_providers.dart';
import 'package:athlete_os/src/features/training/data/repositories/api_workout_repository.dart';
import 'package:athlete_os/src/features/training/data/repositories/mock_workout_repository.dart';
import 'package:athlete_os/src/features/training/domain/entities/exercise_set.dart';
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

  http.Response jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) {
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

      final workout = await repository.getTodayWorkout('athlete-ali');

      expect(workout.id, 'today-workout');
      expect(workout.title, "Today's Workout");
      expect(workout.category, 'Strength');
      expect(workout.focus, 'Lower Body');
      expect(workout.exercises.first.id, 'back-squat-prescription');
      expect(workout.exercises.first.exerciseId, 'back-squat-id');
      expect(workout.exercises.first.name, 'Back Squat');
      expect(workout.exercises.first.coachingNote, 'Stay braced.');
      expect(workout.exercises.first.sets.first.setNumber, 1);
      expect(workout.exercises.first.sets.first.targetReps, 8);
      expect(workout.exercises.first.sets.first.targetWeight, 80);
    });

    test('three exercises and expected set counts are parsed', () async {
      final repository = repositoryFor(
        (_) async => jsonResponse(workoutEnvelope()),
      );

      final workout = await repository.getTodayWorkout('athlete-ali');

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

      final workout = await repository.getTodayWorkout('athlete-ali');

      expect(workout.exercises.first.sets.first.weightUnit, WeightUnit.kg);
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
        (_) async => jsonResponse(
          {
            'error': {
              'code': 'WORKOUT_NOT_FOUND',
              'message': 'Workout not found.',
            },
          },
          statusCode: 404,
        ),
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

    test('provider can still be overridden with MockWorkoutRepository', () async {
      final mockRepository = MockWorkoutRepository();
      final container = ProviderContainer(
        overrides: [workoutRepositoryProvider.overrideWithValue(mockRepository)],
      );
      addTearDown(container.dispose);

      final repository = container.read(workoutRepositoryProvider);
      final workout = await repository.getTodayWorkout('athlete-ali');

      expect(identical(repository, mockRepository), isTrue);
      expect(workout.title, "Today's Workout");
    });
  });
}

Map<String, dynamic> workoutEnvelope({String id = 'today-workout'}) {
  return {
    'data': {
      'id': id,
      'title': "Today's Workout",
      'category': 'Strength',
      'focus': 'Lower Body',
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
          'target_reps': reps,
          'target_weight': weight,
          'weight_unit': 'kg',
        },
    ],
  };
}
