import '../../domain/entities/exercise_prescription.dart';
import '../../domain/entities/exercise_set.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_history_entry.dart';
import '../../domain/entities/workout_result.dart';
import '../../domain/repositories/workout_repository.dart';

class MockWorkoutRepository implements WorkoutRepository {
  MockWorkoutRepository({List<Workout>? workouts}) {
    for (final workout in workouts ?? [_todayWorkout]) {
      _workouts[workout.id] = workout;
    }
  }

  final List<WorkoutResult> _submittedResults = [];
  final Map<String, Workout> _workouts = {};
  static final Workout _todayWorkout = Workout(
    id: 'today-lower-strength',
    title: "Today's Workout",
    category: 'Strength',
    focus: 'Lower Body',
    exercises: [
      ExercisePrescription(
        id: 'back-squat-prescription',
        exerciseId: 'back-squat-id',
        exerciseSlug: 'back-squat',
        name: 'Back Squat',
        category: 'Strength',
        coachingNote: 'Stay braced and control the descent.',
        sets: const [
          ExerciseSet(
            id: 'back-squat-set-1',
            setNumber: 1,
            targetReps: 8,
            targetWeight: 80,
            weightUnit: WeightUnit.kg,
          ),
          ExerciseSet(
            id: 'back-squat-set-2',
            setNumber: 2,
            targetReps: 8,
            targetWeight: 80,
            weightUnit: WeightUnit.kg,
          ),
          ExerciseSet(
            id: 'back-squat-set-3',
            setNumber: 3,
            targetReps: 8,
            targetWeight: 80,
            weightUnit: WeightUnit.kg,
          ),
          ExerciseSet(
            id: 'back-squat-set-4',
            setNumber: 4,
            targetReps: 8,
            targetWeight: 80,
            weightUnit: WeightUnit.kg,
          ),
        ],
      ),
      ExercisePrescription(
        id: 'romanian-deadlift-prescription',
        exerciseId: 'romanian-deadlift-id',
        exerciseSlug: 'romanian-deadlift',
        name: 'Romanian Deadlift',
        category: 'Strength',
        coachingNote: 'Keep the bar close and hips back.',
        sets: const [
          ExerciseSet(
            id: 'romanian-deadlift-set-1',
            setNumber: 1,
            targetReps: 10,
            targetWeight: 70,
            weightUnit: WeightUnit.kg,
          ),
          ExerciseSet(
            id: 'romanian-deadlift-set-2',
            setNumber: 2,
            targetReps: 10,
            targetWeight: 70,
            weightUnit: WeightUnit.kg,
          ),
          ExerciseSet(
            id: 'romanian-deadlift-set-3',
            setNumber: 3,
            targetReps: 10,
            targetWeight: 70,
            weightUnit: WeightUnit.kg,
          ),
        ],
      ),
      ExercisePrescription(
        id: 'walking-lunges-prescription',
        exerciseId: 'walking-lunges-id',
        exerciseSlug: 'walking-lunges',
        name: 'Walking Lunges',
        category: 'Strength',
        coachingNote: 'Smooth steps, tall posture.',
        sets: const [
          ExerciseSet(
            id: 'walking-lunges-set-1',
            setNumber: 1,
            targetReps: 12,
            targetWeight: 20,
            weightUnit: WeightUnit.kg,
          ),
          ExerciseSet(
            id: 'walking-lunges-set-2',
            setNumber: 2,
            targetReps: 12,
            targetWeight: 20,
            weightUnit: WeightUnit.kg,
          ),
          ExerciseSet(
            id: 'walking-lunges-set-3',
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
  Future<Workout?> getTodayWorkout() async => _todayWorkout;

  @override
  Future<Workout> getWorkoutById({required String workoutId}) async {
    final workout = _workouts[workoutId];
    if (workout != null) {
      return workout;
    }
    throw StateError('Workout not found: $workoutId');
  }

  @override
  Future<void> submitWorkoutResult(WorkoutResult result) async {
    _submittedResults.add(result);
  }

  @override
  Future<List<WorkoutHistoryEntry>> getWorkoutHistory({
    int page = 1,
    int perPage = 20,
  }) async => List.unmodifiable(
    _submittedResults
        .map(
          (result) => WorkoutHistoryEntry(
            workoutId: result.workoutId,
            workoutTitle:
                _workouts[result.workoutId]?.title ?? result.workoutId,
            completedAt: result.completedAt,
            setResults: result.setResults,
            notes: result.notes,
          ),
        )
        .skip((page - 1) * perPage)
        .take(perPage),
  );

  List<WorkoutResult> get submittedResults =>
      List.unmodifiable(_submittedResults);
}
