class WorkoutResult {
  const WorkoutResult({
    required this.workoutId,
    required this.athleteId,
    required this.completedSetIds,
    this.notes,
  });

  final String workoutId;
  final String athleteId;
  final List<String> completedSetIds;
  final String? notes;
}
