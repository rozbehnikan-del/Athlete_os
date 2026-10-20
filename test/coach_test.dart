import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:athlete_os/src/core/api/api_client.dart';
import 'package:athlete_os/src/core/api/api_config.dart';
import 'package:athlete_os/src/core/errors/app_exception.dart';
import 'package:athlete_os/src/features/coach/data/api_coach_repository.dart';
import 'package:athlete_os/src/features/coach/domain/coach_models.dart';
import 'package:athlete_os/src/features/coach/application/coach_providers.dart';
import 'package:athlete_os/src/features/coach/presentation/coach_screens.dart';
import 'package:athlete_os/src/features/coach/presentation/create_workout_screen.dart';
import 'package:athlete_os/src/core/theme/app_theme.dart';

final athleteJson = {
  'id': 'athlete',
  'full_name': 'Ali',
  'email': 'ali@test.local',
  'profile': {'goals': 'Train'},
};
final libraryJson = [
  {'id': 'exercise-uuid', 'slug': 'back-squat', 'name': 'Back Squat'},
];
final assignment = WorkoutAssignment(
  title: '  Session  ',
  date: DateTime(2026, 10, 20),
  exercises: [
    const ExerciseAssignment(
      exerciseId: 'exercise-uuid',
      setCount: 2,
      reps: 8,
      weight: 0,
      unit: 'kg',
      note: 'Brace',
    ),
  ],
);

ApiCoachRepository repository(
  Future<http.Response> Function(http.Request) handler,
) => ApiCoachRepository(
  ApiClient(
    config: const ApiConfig(baseUrl: 'http://test.local/'),
    httpClient: MockClient(handler),
  ),
);
http.Response response(Object? data, {int status = 200}) =>
    http.Response(jsonEncode({'data': data}), status);

void main() {
  test('roster parses actual profile and nullable data', () async {
    final repo = repository((r) async {
      expect(r.url.path, '/v1/coaches/me/athletes');
      return response([athleteJson]);
    });
    final athletes = await repo.getAthletes();
    expect(athletes.single.name, 'Ali');
    expect(athletes.single.profile['goals'], 'Train');
  });
  test('athlete detail parses active and recent workouts', () async {
    final repo = repository(
      (r) async => response({
        ...athleteJson,
        'training': {
          'active_workout': {'title': 'Assigned'},
          'recent_workouts': [
            {'workout_title': 'Completed'},
          ],
        },
      }),
    );
    final detail = await repo.getAthlete('athlete');
    expect(detail.activeWorkout!['title'], 'Assigned');
    expect(detail.recentWorkouts.length, 1);
  });
  test('exercise library loads DB IDs and slugs', () async {
    final repo = repository((r) async {
      expect(r.url.path, '/v1/exercises');
      return response(libraryJson);
    });
    expect((await repo.getExercises()).single.id, 'exercise-uuid');
  });
  test(
    'assignment serializes order, targets and explicit units; no coach ID',
    () async {
      final repo = repository((r) async {
        expect(r.method, 'POST');
        expect(r.url.path, '/v1/coaches/me/athletes/athlete/workouts');
        final body = jsonDecode(r.body) as Map;
        expect(body.containsKey('coach_id'), isFalse);
        expect(body['title'], 'Session');
        expect(body['scheduled_for'], '2026-10-20');
        expect(body['exercises'][0]['sets'][1]['set_number'], 2);
        expect(body['exercises'][0]['sets'][0]['weight_unit'], 'kg');
        return response({'id': 'workout'}, status: 201);
      });
      expect(await repo.assign('athlete', assignment), 'workout');
    },
  );
  test('API validation error is visible at repository boundary', () async {
    final repo = repository(
      (r) async =>
          http.Response('{"error":{"message":"Exercise unavailable"}}', 422),
    );
    expect(
      repo.assign('athlete', assignment),
      throwsA(isA<RepositoryException>()),
    );
  });
  test('malformed roster is rejected', () async {
    final repo = repository(
      (r) async => response([
        {'id': 5},
      ]),
    );
    expect(repo.getAthletes(), throwsA(isA<RepositoryException>()));
  });
  for (final brightness in Brightness.values) {
    testWidgets('$brightness coach roster and detail render', (tester) async {
      final repo = repository(
        (r) async => r.url.path.endsWith('/athletes')
            ? response([athleteJson])
            : response({
                ...athleteJson,
                'training': {'active_workout': null, 'recent_workouts': []},
              }),
      );
      Widget screen(Widget child) => ProviderScope(
        overrides: [coachRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
          home: child,
        ),
      );
      await tester.pumpWidget(screen(const CoachHomeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('My Athletes (1)'), findsOneWidget);
      expect(find.text('Ali'), findsOneWidget);
      await tester.pumpWidget(
        screen(const CoachAthleteScreen(athleteId: 'athlete')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Create Workout'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'builder requires title, exercises, reps, weight and explicit unit',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseLibraryProvider.overrideWith(
              (ref) async => [
                const LibraryExercise(
                  id: 'id',
                  slug: 'back-squat',
                  name: 'Back Squat',
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: CreateWorkoutScreen(athleteId: 'athlete'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Assign Workout'));
      await tester.tap(find.text('Assign Workout'));
      await tester.pumpAndSettle();
      expect(find.text('Select a weight unit.'), findsOneWidget);
      expect(find.text('Select an exercise.'), findsOneWidget);
    },
  );
}
