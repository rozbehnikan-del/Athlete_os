import '../../../../core/auth/user_role.dart';
import '../../../../core/errors/app_exception.dart';
import 'exercise_set.dart';

class ExercisePrescription {
  ExercisePrescription({
    required this.id,
    required this.exerciseId,
    required this.exerciseSlug,
    required this.name,
    required Iterable<ExerciseSet> sets,
    this.category,
    this.coachingNote,
  }) : _sets = List.unmodifiable(sets) {
    if (exerciseSlug.isEmpty) {
      throw ArgumentError.value(
        exerciseSlug,
        'exerciseSlug',
        'Exercise slug must be provided for asset selection.',
      );
    }
  }

  final String id;
  final String exerciseId;
  final String exerciseSlug;
  final String name;
  final String? category;
  final String? coachingNote;
  final List<ExerciseSet> _sets;

  List<ExerciseSet> get sets => List.unmodifiable(_sets);

  ExercisePrescription revise({
    required UserRole actor,
    String? category,
    String? coachingNote,
    Iterable<ExerciseSet>? sets,
  }) {
    if (actor != UserRole.coach && actor != UserRole.admin) {
      throw const UnauthorizedOperationException(
        'Only coaches and admins can modify coach-owned exercise prescriptions.',
      );
    }

    return ExercisePrescription(
      id: id,
      exerciseId: exerciseId,
      exerciseSlug: exerciseSlug,
      name: name,
      category: category ?? this.category,
      coachingNote: coachingNote ?? this.coachingNote,
      sets: sets ?? _sets,
    );
  }
}
