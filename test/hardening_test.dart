import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:athlete_os/src/app/athlete_os_app.dart';
import 'package:athlete_os/src/core/api/api_client.dart';
import 'package:athlete_os/src/core/api/api_config.dart';
import 'package:athlete_os/src/features/auth/application/auth_controller.dart';
import 'package:athlete_os/src/features/progress/data/api_progress_repository.dart';
import 'package:athlete_os/src/features/progress/domain/progress_summary.dart';
import 'package:athlete_os/src/features/progress/domain/progress_repository.dart';
import 'package:athlete_os/src/features/progress/application/progress_providers.dart';
import 'package:athlete_os/src/features/training/application/controllers/workout_controller.dart';
import 'package:athlete_os/src/features/training/application/controllers/workout_session_controller.dart';
import 'package:athlete_os/src/features/training/application/workout_providers.dart';
import 'package:athlete_os/src/features/training/data/repositories/mock_workout_repository.dart';
import 'package:athlete_os/src/features/training/domain/entities/workout_history_entry.dart';
import 'helpers/fake_auth_repository.dart';

const emptySummary = ProgressSummary(
  totalWorkouts: 0,
  completedSets: 0,
  prescribedSets: 0,
  recentActivity: [],
);

class _PagedRepository extends MockWorkoutRepository {
  final pages = <int>[];
  @override
  Future<List<WorkoutHistoryEntry>> getWorkoutHistory({
    int page = 1,
    int perPage = 20,
  }) async {
    pages.add(page);
    return [
      for (var i = 0; i < (page == 1 ? 20 : 1); i++)
        WorkoutHistoryEntry(
          workoutId: '$page-$i',
          workoutTitle: 'Session',
          completedAt: DateTime(2026),
          setResults: const [],
        ),
    ];
  }
}

class _SummaryRepository implements ProgressRepository {
  int calls = 0;
  @override
  Future<ProgressSummary> getSummary() async {
    calls++;
    return emptySummary;
  }
}

void main() {
  testWidgets('Home View Plan navigates and has no fake notification control', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
          progressSummaryProvider.overrideWith((ref) async => emptySummary),
        ],
        child: const AthleteOSApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
    await tester.ensureVisible(find.text('View Plan'));
    await tester.tap(find.text('View Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Coach target'), findsOneWidget);
  });
  test(
    'Progress fetches one aggregate endpoint, independent of history size',
    () async {
      var requests = 0;
      final client = ApiClient(
        config: const ApiConfig(baseUrl: 'http://test/'),
        httpClient: MockClient((request) async {
          requests++;
          expect(request.url.path, '/v1/athletes/me/progress-summary');
          return http.Response(
            jsonEncode({
              'data': {
                'total_completed_workouts': 250,
                'total_completed_sets': 1000,
                'total_prescribed_sets': 2000,
                'completion_percentage': 50,
                'recent_activity': [
                  {
                    'workout_id': 'workout',
                    'workout_title': 'Recent',
                    'completed_at': '2026-10-20T12:00:00Z',
                    'completed_sets': 1,
                    'total_sets': 2,
                  },
                ],
              },
            }),
            200,
          );
        }),
      );
      addTearDown(client.close);
      final summary = await ApiProgressRepository(client).getSummary();
      expect(requests, 1);
      expect(summary.totalWorkouts, 250);
      expect(summary.completedSets, 1000);
      expect(summary.completion.grade, 'C');
      expect(summary.recentActivity.length, 1);
    },
  );
  test('History loads additional pages only on explicit request', () async {
    final repo = _PagedRepository();
    final container = ProviderContainer(
      overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    expect((await container.read(workoutHistoryProvider.future)).length, 20);
    expect(repo.pages, [1]);
    await container.read(workoutHistoryProvider.notifier).loadMore();
    expect(container.read(workoutHistoryProvider).requireValue.length, 21);
    await container.read(workoutHistoryProvider.notifier).loadMore();
    expect(repo.pages, [1, 2]);
  });
  test('Successful finish invalidates cached Progress summary', () async {
    final summaryRepo = _SummaryRepository();
    final repo = MockWorkoutRepository();
    final container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(repo),
        progressRepositoryProvider.overrideWithValue(summaryRepo),
      ],
    );
    addTearDown(container.dispose);
    await container.read(progressSummaryProvider.future);
    final workout = (await repo.getTodayWorkout())!;
    await container.read(workoutSessionControllerProvider(workout.id).future);
    final controller = container.read(
      workoutSessionControllerProvider(workout.id).notifier,
    );
    controller.completeCurrentSet();
    await controller.finishWorkout();
    await container.read(progressSummaryProvider.future);
    expect(summaryRepo.calls, 2);
  });
}
