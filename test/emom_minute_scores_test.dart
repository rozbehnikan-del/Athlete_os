import 'package:athlete_os/src/features/training/application/controllers/crossfit_session_controller.dart';
import 'package:athlete_os/src/features/training/domain/entities/crossfit.dart';
import 'package:flutter_test/flutter_test.dart';

const emom = WodDefinition(
  id: 'emom',
  format: WodFormat.emom,
  scoreType: WodScoreType.intervals,
  durationSeconds: 180,
  scalingOptions: [ScalingLevel.rx],
  scoreConfig: {
    'minute_targets': ['10 Wall Balls', '8 Box Jumps', '6 Burpees'],
  },
);

WodResultDraft draft(String score) => WodResultDraft(
  wodId: 'emom',
  scaling: ScalingLevel.rx,
  primaryInput: score,
);

void main() {
  test('EMOM stores each minute in the existing interval score payload', () {
    final score = draft('10,8,6').scoreFor(emom)!;
    expect(score.toJson(), {'type': 'intervals', 'values': [10, 8, 6]});
  });

  test('EMOM rejects results with a missing minute', () {
    expect(draft('10,8').scoreFor(emom), isNull);
    expect(draft('10,,6').scoreFor(emom), isNull);
  });

  test('EMOM rejects fractional or negative actual reps', () {
    expect(draft('10,8.5,6').scoreFor(emom), isNull);
    expect(draft('10,-2,6').scoreFor(emom), isNull);
  });

  test('EMOM accepts zero reps for a missed minute', () {
    final score = draft('10,0,6').scoreFor(emom)!;
    expect(score.toJson()['values'], [10, 0, 6]);
  });
}
