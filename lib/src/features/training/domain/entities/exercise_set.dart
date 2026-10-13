class ExerciseSet {
  const ExerciseSet(this.set, this.reps, this.weight, {this.completed = false});

  final int set;
  final int reps;
  final String weight;
  final bool completed;
}
