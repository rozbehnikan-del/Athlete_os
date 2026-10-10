class ExerciseSet {
  const ExerciseSet(this.set, this.reps, this.weight, {this.completed = false});
  final int set;
  final int reps;
  final String weight;
  final bool completed;
}

class Exercise {
  const Exercise(this.name, this.detail, this.sets);
  final String name;
  final String detail;
  final List<ExerciseSet> sets;
}

class Professional {
  const Professional(this.name, this.role, this.initials);
  final String name;
  final String role;
  final String initials;
}

class Meal {
  const Meal(this.slot, this.name, this.kcal);
  final String slot;
  final String name;
  final String kcal;
}

const exercises = [
  Exercise('Back Squat', '4 x 8 @ 80 kg', [
    ExerciseSet(1, 8, '80 kg', completed: true),
    ExerciseSet(2, 8, '80 kg', completed: true),
    ExerciseSet(3, 8, '80 kg'),
    ExerciseSet(4, 8, '80 kg'),
  ]),
  Exercise('Romanian Deadlift', '4 x 10 @ 60 kg', []),
  Exercise('Walking Lunges', '3 x 12 @ 20 kg', []),
];

const professionals = [
  Professional('Reza Ahmadi', 'Head Coach', 'RA'),
  Professional('Sara Karimi', 'Nutritionist', 'SK'),
  Professional('Dr. Hossein', 'Sports Doctor', 'DH'),
];

const meals = [
  Meal('Breakfast', 'Greek Yogurt Bowl', '420 kcal'),
  Meal('Lunch', 'Grilled Chicken & Rice', '520 kcal'),
  Meal('Snack', 'Protein Shake', '280 kcal'),
  Meal('Dinner', 'Salmon, Quinoa, Vegetables', '630 kcal'),
];

const strengthPoints = [0.22, 0.30, 0.38, 0.43, 0.55, 0.62, 0.74, 0.82];
