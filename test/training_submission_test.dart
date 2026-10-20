import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:athlete_os/src/app/athlete_os_app.dart';
import 'package:athlete_os/src/features/auth/application/auth_controller.dart';
import 'package:athlete_os/src/features/training/application/workout_providers.dart';
import 'package:athlete_os/src/features/training/application/controllers/workout_session_controller.dart';
import 'package:athlete_os/src/features/training/data/repositories/mock_workout_repository.dart';
import 'package:athlete_os/src/features/training/domain/entities/workout_result.dart';
import 'package:athlete_os/src/core/errors/app_exception.dart';
import 'helpers/fake_auth_repository.dart';

class _ControlledSubmit extends MockWorkoutRepository {
  final pending = Completer<void>();
  int calls = 0;
  @override
  Future<void> submitWorkoutResult(WorkoutResult result) async {
    calls++;
    await pending.future;
  }
}

void main() {
  test(
    'concurrent finish calls submit once and preserve partial result',
    () async {
      final repo = _ControlledSubmit();
      final workout = (await repo.getTodayWorkout())!;
      final container = ProviderContainer(
        overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await container.read(workoutSessionControllerProvider(workout.id).future);
      final controller = container.read(
        workoutSessionControllerProvider(workout.id).notifier,
      );
      controller.completeCurrentSet();
      final first = controller.finishWorkout();
      expect(await controller.finishWorkout(), isFalse);
      expect(repo.calls, 1);
      repo.pending.complete();
      expect(await first, isTrue);
      expect(await controller.finishWorkout(), isFalse);
      expect(repo.calls, 1);
    },
  );

  testWidgets(
    'failed partial finish shows inline error and keeps entered values',
    (tester) async {
      final repo = _ControlledSubmit();
      final workout = (await repo.getTodayWorkout())!;
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          workoutRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AthleteOSApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Workout'));
      await tester.pumpAndSettle();
      final controller = container.read(
        workoutSessionControllerProvider(workout.id).notifier,
      );
      controller.updateActualRepsInput('7');
      controller.updateActualWeightInput('42.5');
      controller.completeCurrentSet();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Review and finish'));
      await tester.tap(find.text('Review and finish'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish Workout'));
      await tester.pump();
      expect(find.text('Saving…'), findsOneWidget);
      repo.pending.completeError(const RepositoryException('Offline'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Could not save workout. Your entries are preserved. Please try again.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      final state = container
          .read(workoutSessionControllerProvider(workout.id))
          .requireValue;
      final completed = state.drafts.values.singleWhere((d) => d.completed);
      expect(completed.repsInput, '7');
      expect(completed.weightInput, '42.5');
      expect(state.submitting, isFalse);
      expect(state.finished, isFalse);
    },
  );
}
