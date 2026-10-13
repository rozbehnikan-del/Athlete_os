import '../../domain/entities/exercise_prescription.dart';
import '../../domain/entities/exercise_set.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_result.dart';
import '../../domain/repositories/workout_repository.dart';

class MockWorkoutRepository implements WorkoutRepository {
  MockWorkoutRepository();

  final List<WorkoutResult> _submittedResults = [];
  late final Workout _todayWorkout = Workout(
    id: 'today-lower-strength',
    title: "Today's Workout",
    category: 'Strength',
    focus: 'Lower Body',
    exercises: [
      ExercisePrescription(
        id: 'back-squat-prescription',
        exerciseId: 'back-squat',
        name: 'Back Squat',
        category: 'Strength',
        coachingNote: 'Stay braced and control the descent.',
        sets: const [
          ExerciseSet(
            setNumber: 1,
            targetReps: 8,
            targetWeight: 80,
            weightUnit: WeightUnit.kg,
          ),
          ExerciseSet(
            setNumber: 2,
            targetReps: 8,
            targetWeight: 80,
            weightUnit: WeightUnit.kg,
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
        id: 'romanian-deadlift-prescription',
        exerciseId: 'romanian-deadlift',
        name: 'Romanian Deadlift',
        category: 'Strength',
        coachingNote: 'Keep the bar close and hips back.',
        sets: const [
          ExerciseSet(
            setNumber: 1,
            targetReps: 10,
            targetWeight: 70,
            weightUnit: WeightUnit.kg,
          ),
          ExerciseSet(
            setNumber: 2,
            targetReps: 10,
            targetWeight: 70,
            weightUnit: WeightUnit.kg,
          ),
          ExerciseSet(
            setNumber: 3,
            targetReps: 10,
            targetWeight: 70,
            weightUnit: WeightUnit.kg,
          ),
        ],
      ),
      ExercisePrescription(
        id: 'walking-lunges-prescription',
        exerciseId: 'walking-lunges',
        name: 'Walking Lunges',
        category: 'Strength',
        coachingNote: 'Smooth steps, tall posture.',
        sets: const [
          ExerciseSet(
            setNumber: 1,
            targetReps: 12,
            targetWeight: 20,
            weightUnit: WeightUnit.kg,
          ),
          ExerciseSet(
            setNumber: 2,
            targetReps: 12,
            targetWeight: 20,
            weightUnit: WeightUnit.kg,
          ),
          ExerciseSet(
            setNumber: 3,
            targetReps: 12,
            targetWeight: 20,
            weightUnit: WeightUnit.kg,
          ),
        ],
      ),
    ],
  );

  @override
  Future<Workout> getTodayWorkout(String athleteId) async => _todayWorkout;

  @override
  Future<Workout> getWorkoutById({
    required String athleteId,
    required String workoutId,
  }) async {
    if (workoutId == _todayWorkout.id) {
      return _todayWorkout;
    }
    throw StateError('Workout not found: $workoutId');
  }

  @override
  Future<void> submitWorkoutResult(WorkoutResult result) async {
    _submittedResults.add(result);
  }

  @override
  Future<List<WorkoutResult>> getWorkoutHistory(String athleteId) async =>
      List.unmodifiable(
        _submittedResults.where((result) => result.athleteId == athleteId),
      );

  List<WorkoutResult> get submittedResults =>
      List.unmodifiable(_submittedResults);
}
