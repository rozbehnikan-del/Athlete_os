import 'crossfit.dart';
import 'exercise_prescription.dart';

class Workout {
  Workout({
    required this.id,
    required this.title,
    required this.category,
    required this.focus,
    required Iterable<ExercisePrescription> exercises,
    this.session,
  }) : _exercises = List.unmodifiable(exercises);

  final String id;
  final String title;
  final String category;
  final String focus;
  final TrainingSession? session;
  final List<ExercisePrescription> _exercises;

  List<ExercisePrescription> get exercises => List.unmodifiable(_exercises);
  List<WodDefinition> get scoredWods => session?.scoredWods ?? const [];
  bool get hasCrossFitSession => session != null;
  bool get isWodOnly => exercises.isEmpty && scoredWods.isNotEmpty;
  bool get isMixedSession => exercises.isNotEmpty && scoredWods.isNotEmpty;
}
