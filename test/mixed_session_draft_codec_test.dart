import 'package:athlete_os/src/features/training/application/controllers/crossfit_session_controller.dart';
import 'package:athlete_os/src/features/training/application/controllers/workout_session_controller.dart';
import 'package:athlete_os/src/features/training/application/drafts/mixed_session_draft_codec.dart';
import 'package:athlete_os/src/features/training/domain/entities/crossfit.dart';
import 'package:athlete_os/src/features/training/domain/entities/exercise_set.dart';
import 'package:flutter_test/flutter_test.dart';

const initialSets = <String, SetResultDraft>{
  's1': SetResultDraft(
    setId: 'set-id',
    prescriptionId: 'prescription-id',
    exerciseId: 'exercise-id',
    setNumber: 1,
    repsInput: '5',
    weightInput: '80',
    weightUnit: WeightUnit.kg,
  ),
};

const initialWods = <String, WodResultDraft>{
  'w1': WodResultDraft(wodId: 'w1', scaling: ScalingLevel.rx),
};

void main() {
  test('mixed drafts recover strength, WOD, load attempts and block progress', () {
    final sets = {
      's1': initialSets['s1']!.copyWith(
        repsInput: '4',
        weightInput: '82.5',
        completed: true,
        rpe: 8.0,
      ),
    };
    final wods = {
      'w1': initialWods['w1']!.copyWith(
        scaling: ScalingLevel.scaled,
        primaryInput: '7',
        secondaryInput: '12',
        notes: 'Good pacing',
        loadAttempts: [
          const LoadAttemptDraft(id: 'a1', loadInput: '90', successful: false),
          const LoadAttemptDraft(id: 'a2', loadInput: '85', successful: true),
        ],
      ),
    };
    final encoded = MixedSessionDraftCodec.encode(
      workoutId: 'workout-1',
      sets: sets,
      wods: wods,
      blockIndex: 2,
      completedBlockIds: {'warmup', 'strength'},
    );
    final restored = MixedSessionDraftCodec.restore(
      encoded,
      workoutId: 'workout-1',
      sets: initialSets,
      wods: initialWods,
      blockIds: ['warmup', 'strength', 'metcon', 'accessory'],
    )!;
    expect(restored.sets['s1']!.completed, isTrue);
    expect(restored.sets['s1']!.weightInput, '82.5');
    expect(restored.wods['w1']!.secondaryInput, '12');
    expect(restored.wods['w1']!.scaling, ScalingLevel.scaled);
    expect(restored.wods['w1']!.loadAttempts[0].successful, isFalse);
    expect(restored.blockIndex, 2);
    expect(restored.completedBlockIds, {'warmup', 'strength'});
  });

  test('drafts from another workout are ignored', () {
    final snapshot = MixedSessionDraftCodec.encode(
      workoutId: 'workout-A',
      sets: initialSets,
      wods: initialWods,
      blockIndex: 0,
      completedBlockIds: const {},
    );
    expect(
      MixedSessionDraftCodec.restore(
        snapshot,
        workoutId: 'workout-B',
        sets: initialSets,
        wods: initialWods,
        blockIds: ['warmup'],
      ),
      isNull,
    );
  });

  test('invalid snapshots never block the session', () {
    expect(
      MixedSessionDraftCodec.restore(
        '{bad json',
        workoutId: 'workout-1',
        sets: initialSets,
        wods: initialWods,
        blockIds: ['warmup'],
      ),
      isNull,
    );
  });
}
