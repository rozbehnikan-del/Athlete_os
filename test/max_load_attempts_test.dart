import 'package:athlete_os/src/features/training/application/controllers/crossfit_session_controller.dart';
import 'package:athlete_os/src/features/training/domain/entities/crossfit.dart';
import 'package:flutter_test/flutter_test.dart';

const maxLoadWod = WodDefinition(
  id: 'maxload-wod',
  format: WodFormat.maxLoad,
  scoreType: WodScoreType.load,
  scalingOptions: [ScalingLevel.rx],
  scoreConfig: {},
);

void main() {
  test('best load comes from successful attempts, not failed maximum', () {
    const draft = WodResultDraft(
      wodId: 'maxload-wod',
      scaling: ScalingLevel.rx,
      unit: 'kg',
      loadAttempts: [
        LoadAttemptDraft(id: '1', loadInput: '80', successful: true),
        LoadAttemptDraft(id: '2', loadInput: '95', successful: false),
        LoadAttemptDraft(id: '3', loadInput: '87.5', successful: true),
      ],
    );
    final score = draft.scoreFor(maxLoadWod)! as LoadWodScore;
    expect(score.load, 87.5);
    expect(score.toJson()['attempts'], [
      {'load': 80.0, 'successful': true},
      {'load': 95.0, 'successful': false},
      {'load': 87.5, 'successful': true},
    ]);
  });

  test('all failed attempts cannot produce a Max Load score', () {
    const draft = WodResultDraft(
      wodId: 'maxload-wod',
      scaling: ScalingLevel.rx,
      loadAttempts: [
        LoadAttemptDraft(id: '1', loadInput: '100', successful: false),
      ],
    );
    expect(draft.scoreFor(maxLoadWod), isNull);
  });

  test('invalid attempt weight blocks submission', () {
    const draft = WodResultDraft(
      wodId: 'maxload-wod',
      scaling: ScalingLevel.rx,
      loadAttempts: [
        LoadAttemptDraft(id: '1', loadInput: '80', successful: true),
        LoadAttemptDraft(id: '2', loadInput: 'oops', successful: false),
      ],
    );
    expect(draft.scoreFor(maxLoadWod), isNull);
  });

  test('existing simple load scores stay backward compatible', () {
    const draft = WodResultDraft(
      wodId: 'maxload-wod',
      scaling: ScalingLevel.rx,
      primaryInput: '92',
    );
    final score = draft.scoreFor(maxLoadWod)!;
    expect(score.toJson(), {'type': 'load', 'load': 92.0, 'unit': 'kg'});
  });
}
