import '../domain/entities/exercise_prescription.dart';
import '../domain/entities/exercise_set.dart';

String exerciseImagePath(String exerciseId) => switch (exerciseId) {
  'back-squat' => 'assets/images/exercises/back_squat.jpg',
  'romanian-deadlift' => 'assets/images/exercises/romanian_deadlift.jpg',
  'walking-lunges' => 'assets/images/exercises/walking_lunges.jpg',
  _ => 'assets/images/exercises/back_squat.jpg',
};

String exerciseHeroImagePath(String exerciseId) => switch (exerciseId) {
  'back-squat' => 'assets/images/exercises/back_squat_hero.jpg',
  _ => exerciseImagePath(exerciseId),
};

String weightUnitLabel(WeightUnit unit) => switch (unit) {
  WeightUnit.kg => 'kg',
  WeightUnit.lb => 'lb',
};

String targetWeightLabel(ExerciseSet set) {
  final targetWeight = set.targetWeight;
  final weightUnit = set.weightUnit;
  if (targetWeight == null || weightUnit == null) {
    return 'target not set';
  }
  final weight = targetWeight == targetWeight.roundToDouble()
      ? targetWeight.round().toString()
      : targetWeight.toStringAsFixed(1);
  return '$weight ${weightUnitLabel(weightUnit)}';
}

String exercisePrescriptionDetail(ExercisePrescription exercise) {
  if (exercise.sets.isEmpty) {
    return '';
  }
  final firstSet = exercise.sets.first;
  final targetReps = firstSet.targetReps;
  if (targetReps == null ||
      firstSet.targetWeight == null ||
      firstSet.weightUnit == null) {
    return '${exercise.sets.length} sets';
  }
  return '${exercise.sets.length} x $targetReps @ ${targetWeightLabel(firstSet)}';
}
