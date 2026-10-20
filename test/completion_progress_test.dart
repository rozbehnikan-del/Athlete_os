import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:athlete_os/src/app/athlete_os_app.dart';
import 'package:athlete_os/src/features/auth/application/auth_controller.dart';
import 'package:athlete_os/src/features/training/application/controllers/workout_controller.dart';
import 'package:athlete_os/src/features/training/domain/entities/completion_grade.dart';
import 'package:athlete_os/src/features/training/domain/entities/workout_history_entry.dart';
import 'package:athlete_os/src/features/progress/domain/progress_metrics.dart';
import 'helpers/fake_auth_repository.dart';

WorkoutHistoryEntry entry(int completed, int total, {int day = 1}) =>
    WorkoutHistoryEntry(
      workoutId: '$day',
      workoutTitle: 'Real session $day',
      completedAt: DateTime(2026, 10, day),
      setResults: const [],
      prescribedSets: total,
      recordedCompletedSets: completed,
    );

void main() {
  for (final (completed, total, grade) in [
    (100, 100, 'A'),
    (90, 100, 'A'),
    (899, 1000, 'B'),
    (75, 100, 'B'),
    (749, 1000, 'C'),
    (50, 100, 'C'),
    (49, 100, 'D'),
    (0, 10, 'D'),
  ]) {
    test('$completed/$total has grade $grade without rounding', () {
      expect(
        CompletionGrade(completedSets: completed, totalSets: total).grade,
        grade,
      );
    });
  }
  test('empty prescription is ungraded', () {
    final grade = CompletionGrade(completedSets: 0, totalSets: 0);
    expect(grade.grade, isNull);
    expect(grade.percentage, isNull);
  });
  test('progress weights prescription totals rather than averaging grades', () {
    final metrics = ProgressMetrics([entry(1, 2), entry(9, 10, day: 2)]);
    expect(metrics.completedSets, 10);
    expect(metrics.prescribedSets, 12);
    expect(metrics.completion.percentage, closeTo(83.3333, .001));
    expect(metrics.completion.grade, 'B');
    expect(metrics.recentChange, isNull);
  });
  test('trend compares six actual sessions in date order', () {
    final metrics = ProgressMetrics([
      for (var day = 1; day <= 6; day++) entry(day > 3 ? 10 : 5, 10, day: day),
    ]);
    expect(metrics.recentChange, 50);
  });
  testWidgets('Progress displays real history and Completion Grade', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          workoutHistoryProvider.overrideWith((ref) async => [entry(1, 2)]),
          workoutControllerProvider.overrideWith(() => _NoWorkout()),
        ],
        child: const AthleteOSApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.show_chart_rounded).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('1 completed workouts'), findsOneWidget);
    expect(find.text('1 completed sets'), findsOneWidget);
    expect(find.textContaining('1/2 sets\nCompletion Grade C'), findsOneWidget);
    expect(find.textContaining('125 kg'), findsNothing);
  });
}

class _NoWorkout extends WorkoutController {
  @override
  Future<Never?> build() async => null;
}
