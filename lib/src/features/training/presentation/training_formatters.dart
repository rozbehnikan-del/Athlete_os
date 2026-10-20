import '../domain/entities/exercise_prescription.dart';
import '../domain/entities/exercise_set.dart';
import '../domain/entities/workout.dart';

String workoutMetadata(Workout workout) {
  final category = workout.category.trim();
  final focus = workout.focus.trim();
  if (category.isEmpty) return focus;
  if (focus.isEmpty) return category;
  return '$category ($focus)';
}

String exerciseImagePath(String slug) => switch (slug) {
  'back-squat' => 'assets/images/exercises/back_squat.jpg',
  'romanian-deadlift' => 'assets/images/exercises/romanian_deadlift.jpg',
  'walking-lunges' => 'assets/images/exercises/walking_lunges.jpg',
  _ => 'assets/images/exercises/back_squat.jpg',
};

String exerciseHeroImagePath(String slug) => switch (slug) {
  'back-squat' => 'assets/images/exercises/back_squat_hero.jpg',
  _ => exerciseImagePath(slug),
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
