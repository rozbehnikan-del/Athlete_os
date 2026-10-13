import '../../domain/entities/exercise_prescription.dart';
import '../../domain/entities/exercise_set.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_result.dart';
import '../../domain/repositories/workout_repository.dart';

class MockWorkoutRepository implements WorkoutRepository {
  MockWorkoutRepository();

  final List<WorkoutResult> _submittedResults = [];

  @override
  Future<Workout> getTodayWorkout(String athleteId) async => Workout(
    id: 'today-lower-strength',
    title: "Today's Workout",
    category: 'Strength',
    focus: 'Lower Body',
    exercises: [
      ExercisePrescription(
        id: 'back-squat',
        name: 'Back Squat',
        detail: '4 x 8 @ 80 kg',
        imagePath: 'assets/images/exercises/back_squat.jpg',
        sets: const [
          ExerciseSet(1, 8, '80 kg', completed: true),
          ExerciseSet(2, 8, '80 kg', completed: true),
          ExerciseSet(3, 8, '80 kg'),
          ExerciseSet(4, 8, '80 kg'),
        ],
      ),
      ExercisePrescription(
        id: 'romanian-deadlift',
        name: 'Romanian Deadlift',
        detail: '4 x 10 @ 60 kg',
        imagePath: 'assets/images/exercises/romanian_deadlift.jpg',
        sets: const [],
      ),
      ExercisePrescription(
        id: 'walking-lunges',
        name: 'Walking Lunges',
        detail: '3 x 12 @ 20 kg',
        imagePath: 'assets/images/exercises/walking_lunges.jpg',
        sets: const [],
      ),
    ],
  );

  @override
  Future<void> submitWorkoutResult(WorkoutResult result) async {
    _submittedResults.add(result);
  }

  List<WorkoutResult> get submittedResults => List.unmodifiable(_submittedResults);
}
