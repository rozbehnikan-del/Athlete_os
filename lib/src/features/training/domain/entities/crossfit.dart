enum TrainingBlockType { warmup, strength, skill, metcon, accessory }

enum WodFormat {
  forTime,
  amrap,
  emom,
  roundsForTime,
  chipper,
  intervals,
  maxLoad,
  maxReps,
  calories,
  distance,
  tabata,
  custom,
}

enum WodScoreType {
  time,
  roundsReps,
  load,
  reps,
  calories,
  distance,
  intervals,
  none,
}

enum ScalingLevel { rx, scaled, custom, none }

class WodDefinition {
  const WodDefinition({
    required this.id,
    required this.format,
    required this.scoreType,
    required this.scalingOptions,
    required this.scoreConfig,
    this.durationSeconds,
    this.timeCapSeconds,
    this.rounds,
  });

  final String id;
  final WodFormat format;
  final WodScoreType scoreType;
  final int? durationSeconds;
  final int? timeCapSeconds;
  final int? rounds;
  final List<ScalingLevel> scalingOptions;
  final Map<String, dynamic> scoreConfig;
}

class TrainingBlock {
  const TrainingBlock({
    required this.id,
    required this.order,
    required this.type,
    required this.title,
    required this.prescription,
    this.coachNote,
    this.wod,
  });

  final String id;
  final int order;
  final TrainingBlockType type;
  final String title;
  final String? coachNote;
  final Map<String, dynamic> prescription;
  final WodDefinition? wod;
}

class TrainingSession {
  const TrainingSession({required this.id, required this.blocks});

  final String id;
  final List<TrainingBlock> blocks;

  List<WodDefinition> get scoredWods => [
    for (final block in blocks)
      if (block.wod != null && block.wod!.scoreType != WodScoreType.none)
        block.wod!,
  ];
}

sealed class WodScore {
  const WodScore();
  WodScoreType get type;
  Map<String, dynamic> toJson();
}

class TimeWodScore extends WodScore {
  const TimeWodScore(this.seconds);
  final int seconds;
  @override
  WodScoreType get type => WodScoreType.time;
  @override
  Map<String, dynamic> toJson() => {'type': 'time', 'seconds': seconds};
}

class RoundsRepsWodScore extends WodScore {
  const RoundsRepsWodScore({required this.rounds, required this.reps});
  final int rounds;
  final int reps;
  @override
  WodScoreType get type => WodScoreType.roundsReps;
  @override
  Map<String, dynamic> toJson() => {
    'type': 'rounds_reps',
    'rounds': rounds,
    'reps': reps,
  };
}

class LoadAttempt {
  const LoadAttempt({required this.load, required this.successful});

  final double load;
  final bool successful;

  Map<String, dynamic> toJson() => {
    'load': load,
    'successful': successful,
  };
}

class LoadWodScore extends WodScore {
  const LoadWodScore({
    required this.load,
    required this.unit,
    this.attempts = const [],
  });

  final double load;
  final String unit;
  final List<LoadAttempt> attempts;

  @override
  WodScoreType get type => WodScoreType.load;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'load',
    'load': load,
    'unit': unit,
    if (attempts.isNotEmpty)
      'attempts': [for (final attempt in attempts) attempt.toJson()],
  };
}

class RepsWodScore extends WodScore {
  const RepsWodScore(this.reps);
  final int reps;
  @override
  WodScoreType get type => WodScoreType.reps;
  @override
  Map<String, dynamic> toJson() => {'type': 'reps', 'reps': reps};
}

class CaloriesWodScore extends WodScore {
  const CaloriesWodScore(this.calories);
  final int calories;
  @override
  WodScoreType get type => WodScoreType.calories;
  @override
  Map<String, dynamic> toJson() => {'type': 'calories', 'calories': calories};
}

class DistanceWodScore extends WodScore {
  const DistanceWodScore({required this.distance, required this.unit});
  final double distance;
  final String unit;
  @override
  WodScoreType get type => WodScoreType.distance;
  @override
  Map<String, dynamic> toJson() => {
    'type': 'distance',
    'distance': distance,
    'unit': unit,
  };
}

class IntervalsWodScore extends WodScore {
  const IntervalsWodScore(this.values);
  final List<double> values;
  @override
  WodScoreType get type => WodScoreType.intervals;
  @override
  Map<String, dynamic> toJson() => {'type': 'intervals', 'values': values};
}

class NoWodScore extends WodScore {
  const NoWodScore();
  @override
  WodScoreType get type => WodScoreType.none;
  @override
  Map<String, dynamic> toJson() => {'type': 'none'};
}

class WodResultEntry {
  const WodResultEntry({
    required this.wodId,
    required this.scaling,
    required this.score,
    this.dnf = false,
    this.rpe,
    this.notes,
  });

  final String wodId;
  final ScalingLevel scaling;
  final WodScore score;
  final bool dnf;
  final double? rpe;
  final String? notes;
}
