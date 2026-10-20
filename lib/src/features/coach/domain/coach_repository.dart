import 'coach_models.dart';

abstract class CoachRepository {
  Future<List<CoachAthlete>> getAthletes();
  Future<AthleteTrainingDetail> getAthlete(String id);
  Future<List<LibraryExercise>> getExercises();
  Future<String> assign(String athleteId, WorkoutAssignment workout);
}
