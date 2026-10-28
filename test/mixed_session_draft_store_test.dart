import 'package:athlete_os/src/features/training/application/controllers/crossfit_session_controller.dart';
import 'package:athlete_os/src/features/training/application/controllers/workout_session_controller.dart';
import 'package:athlete_os/src/features/training/application/drafts/mixed_session_draft_store.dart';
import 'package:athlete_os/src/features/training/domain/entities/crossfit.dart';
import 'package:athlete_os/src/features/training/domain/entities/exercise_set.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const defaultSet = SetResultDraft(
    setId: 'set-1',
    prescriptionId: 'prescription-1',
    exerciseId: 'squat',
    setNumber: 1,
    repsInput: '5',
    weightInput: '80',
    weightUnit: WeightUnit.kg,
  );
  const defaultWod = WodResultDraft(
    wodId: 'wod-1',
    scaling: ScalingLevel.rx,
    unit: 'kg',
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('snapshot survives save and reload with mixed scoring fields', () async {
    final store = MixedSessionDraftStore();
    final snapshot = MixedSessionDraftSnapshot(
      currentBlockIndex: 2,
      completedBlockIds: {'warmup', 'strength'},
      setDrafts: {
        'prescription-1:1': defaultSet.copyWith(
          repsInput: '6',
          weightInput: '87.5',
          completed: true,
          rpe: 8.5,
        ),
      },
      wodDrafts: {
        'wod-1': defaultWod.copyWith(
          primaryInput: '10,8,6',
          secondaryInput: '3',
          dnf: false,
          notes: 'Round one',
          loadAttempts: const [
            LoadAttemptDraft(id: 'attempt-1', loadInput: '80', successful: true),
            LoadAttemptDraft(id: 'attempt-2', loadInput: '90', successful: false),
          ],
        ),
      },
    );
    await store.save('workout-1', snapshot.toJson());

    final reopened = MixedSessionDraftStore();
    final restored = MixedSessionDraftSnapshot.restore(
      await reopened.load('workout-1'),
      defaultSets: {'prescription-1:1': defaultSet},
      defaultWods: {'wod-1': defaultWod},
      blockIds: ['warmup', 'strength', 'metcon', 'cooldown'],
    );
    expect(restored.currentBlockIndex, 2);
    expect(restored.completedBlockIds, {'warmup', 'strength'});
    expect(restored.setDrafts['prescription-1:1']!.weightInput, '87.5');
    expect(restored.setDrafts['prescription-1:1']!.completed, true);
    expect(restored.setDrafts['prescription-1:1']!.rpe, 8.5);
    expect(restored.wodDrafts['wod-1']!.primaryInput, '10,8,6');
    expect(restored.wodDrafts['wod-1']!.notes, 'Round one');
    expect(restored.wodDrafts['wod-1']!.loadAttempts.length, 2);
    expect(restored.wodDrafts['wod-1']!.loadAttempts.last.successful, false);

    expect(await reopened.load('other-workout'), isNull);
    await reopened.clear('workout-1');
    expect(await reopened.load('workout-1'), isNull);
  });

  test('stale identifiers and completed blocks cannot override prescription', () {
    final restored = MixedSessionDraftSnapshot.restore(
      {
        'version': 1,
        'currentBlockIndex': 99,
        'completedBlockIds': ['warmup', 'unknown'],
        'sets': {
          'prescription-1:1': {
            'setId': 'foreign-set',
            'reps': '999',
            'weight': '1000',
            'completed': true,
          },
        },
        'wods': {'old-wod': {'primary': '999'}},
      },
      defaultSets: {'prescription-1:1': defaultSet},
      defaultWods: {'wod-1': defaultWod},
      blockIds: ['warmup', 'strength'],
    );
    expect(restored.currentBlockIndex, 1);
    expect(restored.completedBlockIds, {'warmup'});
    expect(restored.setDrafts['prescription-1:1']!.repsInput, '5');
    expect(restored.wodDrafts['wod-1']!.primaryInput, '');
  });

  test('latest queued write wins and failed cache content is ignored', () async {
    final store = MixedSessionDraftStore();
    final first = store.save('workout-1', {'version': 1, 'flag': 'old'});
    final second = store.save('workout-1', {'version': 1, 'flag': 'new'});
    await Future.wait([first, second]);
    expect((await store.load('workout-1'))!['flag'], 'new');

    final restored = MixedSessionDraftSnapshot.restore(
      {'version': 999, 'currentBlockIndex': 3},
      defaultSets: {'prescription-1:1': defaultSet},
      defaultWods: {'wod-1': defaultWod},
      blockIds: ['warmup', 'strength'],
    );
    expect(restored.currentBlockIndex, 0);
    expect(restored.setDrafts['prescription-1:1']!.weightInput, '80');
  });
}
