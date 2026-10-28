import 'crossfit.dart';

/// A deterministic view of a WOD clock, based on elapsed monotonic time.
/// The UI is responsible for starting, pausing and resetting its Stopwatch.
class WodTimerReading {
  const WodTimerReading({
    required this.seconds,
    required this.countsUp,
    required this.ended,
    this.emomMinute,
    this.emomTotalMinutes,
  });

  /// The value shown on the timer: elapsed for For Time or remaining otherwise.
  final int seconds;
  final bool countsUp;
  final bool ended;
  final int? emomMinute;
  final int? emomTotalMinutes;

  static WodTimerReading? forWod(WodDefinition wod, Duration elapsed) {
    final elapsedSeconds = elapsed.inSeconds < 0 ? 0 : elapsed.inSeconds;
    final countsUp = switch (wod.format) {
      WodFormat.forTime || WodFormat.roundsForTime || WodFormat.chipper => true,
      _ => false,
    };

    // Time-capped For Time is still a stopwatch (not a countdown).
    final limit = countsUp
        ? wod.timeCapSeconds
        : wod.durationSeconds ?? wod.timeCapSeconds;

    if (!countsUp && (limit == null || limit <= 0)) return null;

    final bounded = limit == null
        ? elapsedSeconds
        : elapsedSeconds.clamp(0, limit).toInt();

    final ended = limit != null && elapsedSeconds >= limit;
    final minuteCount = wod.format == WodFormat.emom && limit != null
        ? (limit + 59) ~/ 60
        : null;
    final minute = minuteCount == null
        ? null
        : (elapsedSeconds ~/ 60 + 1).clamp(1, minuteCount).toInt();

    return WodTimerReading(
      seconds: countsUp ? bounded : limit! - bounded,
      countsUp: countsUp,
      ended: ended,
      emomMinute: minute,
      emomTotalMinutes: minuteCount,
    );
  }
}
