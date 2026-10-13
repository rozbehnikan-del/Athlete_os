import '../../../../core/auth/user_role.dart';
import '../../../../core/errors/app_exception.dart';
import 'exercise_set.dart';

class ExercisePrescription {
  ExercisePrescription({
    required this.id,
    required this.name,
    required this.detail,
    required this.imagePath,
    required Iterable<ExerciseSet> sets,
  }) : _sets = List.unmodifiable(sets);

  final String id;
  final String name;
  final String detail;
  final String imagePath;
  final List<ExerciseSet> _sets;

  List<ExerciseSet> get sets => List.unmodifiable(_sets);

  ExercisePrescription revise({
    required UserRole actor,
    String? detail,
    Iterable<ExerciseSet>? sets,
  }) {
    if (actor == UserRole.athlete) {
      throw const UnauthorizedOperationException(
        'Athletes cannot modify coach-owned exercise prescriptions.',
      );
    }

    return ExercisePrescription(
      id: id,
      name: name,
      detail: detail ?? this.detail,
      imagePath: imagePath,
      sets: sets ?? _sets,
    );
  }
}
