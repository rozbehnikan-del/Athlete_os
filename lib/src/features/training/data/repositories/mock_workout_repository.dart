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
        exerciseId: 'back-squat',
        name: 'Back Squat',
        category: 'Strength',
        sets: const [
          ExerciseSet(
            setNumber: 1,
            targetReps: 8,
            targetWeight: 80,
            weightUnit: WeightUnit.kg,
            completed: true,
          ),
          ExerciseSet(
            setNumber: 2,
            targetReps: 8,
            targetWeight: 80,
            weightUnit: WeightUnit.kg,
            completed: true,
          ),
          ExerciseSet(
            setNumber: 3,
            targetReps: 8,
            targetWeight: 80,
            weightUnit: WeightUnit.kg,
          ),
          ExerciseSet(
            setNumber: 4,
            targetReps: 8,
            targetWeight: 80,
            weightUnit: WeightUnit.kg,
          ),
        ],
      ),
      ExercisePrescription(
        id: 'romanian-deadlift',
        exerciseId: 'romanian-deadlift',
        name: 'Romanian Deadlift',
        category: 'Strength',
        sets: const [],
      ),
      ExercisePrescription(
        id: 'walking-lunges',
        exerciseId: 'walking-lunges',
        name: 'Walking Lunges',
        category: 'Strength',
        sets: const [],
      ),
    ],
  );

  @override
  Future<void> submitWorkoutResult(WorkoutResult result) async {
    _submittedResults.add(result);
  }

  List<WorkoutResult> get submittedResults =>
      List.unmodifiable(_submittedResults);
}
