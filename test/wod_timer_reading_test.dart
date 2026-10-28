import 'package:athlete_os/src/features/training/domain/entities/crossfit.dart';
import 'package:athlete_os/src/features/training/domain/entities/wod_timer.dart';
import 'package:flutter_test/flutter_test.dart';

WodDefinition wod(
  WodFormat format, {
  int? durationSeconds,
  int? timeCapSeconds,
}) => WodDefinition(
  id: 'wod-1',
  format: format,
  scoreType: WodScoreType.time,
  scalingOptions: const [],
  scoreConfig: const {},
  durationSeconds: durationSeconds,
  timeCapSeconds: timeCapSeconds,
);

void main() {
  test('For Time runs upward without a cap', () {
    final reading = WodTimerReading.forWod(
      wod(WodFormat.forTime),
      const Duration(seconds: 75),
    )!;
    expect(reading.seconds, 75);
    expect(reading.countsUp, isTrue);
    expect(reading.ended, isFalse);
  });

  test('For Time stops at the cap and never shows more than the cap', () {
    final reading = WodTimerReading.forWod(
      wod(WodFormat.roundsForTime, timeCapSeconds: 90),
      const Duration(seconds: 99),
    )!;
    expect(reading.seconds, 90);
    expect(reading.ended, isTrue);
  });

  test('AMRAP counts down based on actual elapsed time', () {
    final definition = wod(WodFormat.amrap, durationSeconds: 720);
    final reading = WodTimerReading.forWod(
      definition,
      const Duration(seconds: 66),
    )!;
    expect(reading.seconds, 654);
    expect(reading.countsUp, isFalse);
    expect(reading.ended, isFalse);
    expect(
      WodTimerReading.forWod(definition, const Duration(seconds: 730))!.seconds,
      0,
    );
    expect(
      WodTimerReading.forWod(definition, const Duration(seconds: 730))!.ended,
      isTrue,
    );
  });

  test('EMOM reports the current minute and holds the final minute at cap', () {
    final definition = wod(WodFormat.emom, durationSeconds: 180);
    final first = WodTimerReading.forWod(
      definition,
      const Duration(seconds: 0),
    )!;
    final second = WodTimerReading.forWod(
      definition,
      const Duration(seconds: 61),
    )!;
    final ended = WodTimerReading.forWod(
      definition,
      const Duration(seconds: 190),
    )!;
    expect(first.emomMinute, 1);
    expect(second.emomMinute, 2);
    expect(second.emomTotalMinutes, 3);
    expect(second.seconds, 119);
    expect(ended.emomMinute, 3);
    expect(ended.seconds, 0);
    expect(ended.ended, isTrue);
  });

  test('timer is unavailable when a countdown WOD has no duration', () {
    expect(
      WodTimerReading.forWod(
        wod(WodFormat.amrap),
        const Duration(seconds: 0),
      ),
      isNull,
    );
  });
}
