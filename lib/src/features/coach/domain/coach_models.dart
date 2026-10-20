class CoachAthlete {
  const CoachAthlete({
    required this.id,
    required this.name,
    this.email,
    this.profile = const {},
  });
  final String id;
  final String name;
  final String? email;
  final Map<String, dynamic> profile;
}

class AthleteTrainingDetail {
  const AthleteTrainingDetail({
    required this.athlete,
    this.activeWorkout,
    required this.recentWorkouts,
  });
  final CoachAthlete athlete;
  final Map<String, dynamic>? activeWorkout;
  final List<Map<String, dynamic>> recentWorkouts;
}

class LibraryExercise {
  const LibraryExercise({
    required this.id,
    required this.slug,
    required this.name,
  });
  final String id;
  final String slug;
  final String name;
}

class ExerciseAssignment {
  const ExerciseAssignment({
    required this.exerciseId,
    required this.setCount,
    required this.reps,
    required this.weight,
    required this.unit,
    this.note,
  });
  final String exerciseId;
  final int setCount;
  final int reps;
  final double weight;
  final String unit;
  final String? note;

  Map<String, dynamic> toJson(int order) => {
    'exercise_id': exerciseId,
    'order': order,
    'coaching_note': note,
    'sets': [
      for (var i = 1; i <= setCount; i++)
        {
          'set_number': i,
          'target_reps': reps,
          'target_weight': weight,
          'weight_unit': unit,
        },
    ],
  };
}

class WorkoutAssignment {
  const WorkoutAssignment({
    required this.title,
    required this.date,
    required this.exercises,
    this.category,
    this.focus,
  });
  final String title;
  final DateTime date;
  final String? category;
  final String? focus;
  final List<ExerciseAssignment> exercises;

  Map<String, dynamic> toJson() => {
    'title': title.trim(),
    'category': category,
    'focus': focus,
    'scheduled_for':
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    'exercises': [
      for (var i = 0; i < exercises.length; i++) exercises[i].toJson(i + 1),
    ],
  };
}
