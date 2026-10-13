import 'exercise_prescription.dart';

class Workout {
  Workout({
    required this.id,
    required this.title,
    required this.category,
    required this.focus,
    required Iterable<ExercisePrescription> exercises,
  }) : _exercises = List.unmodifiable(exercises);

  final String id;
  final String title;
  final String category;
  final String focus;
  final List<ExercisePrescription> _exercises;

  List<ExercisePrescription> get exercises => List.unmodifiable(_exercises);
}
