enum WeightUnit { kg, lb }

class ExerciseSet {
  const ExerciseSet({
    required this.setNumber,
    required this.targetReps,
    required this.targetWeight,
    required this.weightUnit,
  });

  final int setNumber;
  final int targetReps;
  final double targetWeight;
  final WeightUnit weightUnit;
}
