import '../domain/entities/exercise_prescription.dart';
import '../domain/entities/exercise_set.dart';

String exerciseImagePath(String exerciseId) => switch (exerciseId) {
  'back-squat' => 'assets/images/exercises/back_squat.jpg',
  'romanian-deadlift' => 'assets/images/exercises/romanian_deadlift.jpg',
  'walking-lunges' => 'assets/images/exercises/walking_lunges.jpg',
  _ => 'assets/images/exercises/back_squat.jpg',
};

String weightUnitLabel(WeightUnit unit) => switch (unit) {
  WeightUnit.kg => 'kg',
  WeightUnit.lb => 'lb',
};

String targetWeightLabel(ExerciseSet set) {
  final weight = set.targetWeight == set.targetWeight.roundToDouble()
      ? set.targetWeight.round().toString()
      : set.targetWeight.toStringAsFixed(1);
  return '$weight ${weightUnitLabel(set.weightUnit)}';
}

String exercisePrescriptionDetail(ExercisePrescription exercise) {
  if (exercise.sets.isEmpty) {
    return '';
  }
  final firstSet = exercise.sets.first;
  return '${exercise.sets.length} x ${firstSet.targetReps} @ ${targetWeightLabel(firstSet)}';
}
