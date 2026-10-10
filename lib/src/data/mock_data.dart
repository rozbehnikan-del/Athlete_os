class ExerciseSet {
  const ExerciseSet(this.set, this.reps, this.weight, {this.completed = false});
  final int set;
  final int reps;
  final String weight;
  final bool completed;
}

class Exercise {
  const Exercise(this.name, this.detail, this.imagePath, this.sets);
  final String name;
  final String detail;
  final String imagePath;
  final List<ExerciseSet> sets;
}

class Professional {
  const Professional(this.name, this.role, this.initials, this.imagePath);
  final String name;
  final String role;
  final String initials;
  final String imagePath;
}

class Meal {
  const Meal(this.slot, this.name, this.kcal, this.imagePath);
  final String slot;
  final String name;
  final String kcal;
  final String imagePath;
}

const exercises = [
  Exercise('Back Squat', '4 x 8 @ 80 kg', 'assets/images/exercises/back_squat.jpg', [
    ExerciseSet(1, 8, '80 kg', completed: true),
    ExerciseSet(2, 8, '80 kg', completed: true),
    ExerciseSet(3, 8, '80 kg'),
    ExerciseSet(4, 8, '80 kg'),
  ]),
  Exercise('Romanian Deadlift', '4 x 10 @ 60 kg', 'assets/images/exercises/romanian_deadlift.jpg', []),
  Exercise('Walking Lunges', '3 x 12 @ 20 kg', 'assets/images/exercises/walking_lunges.jpg', []),
];

const professionals = [
  Professional('Reza Ahmadi', 'Head Coach', 'RA', 'assets/images/professionals/coach_reza.jpg'),
  Professional('Sara Karimi', 'Nutritionist', 'SK', 'assets/images/professionals/nutritionist_sara.jpg'),
  Professional('Dr. Hossein', 'Sports Doctor', 'DH', 'assets/images/professionals/doctor_hossein.jpg'),
];

const meals = [
  Meal('Breakfast', 'Greek Yogurt Bowl', '420 kcal', 'assets/images/nutrition/breakfast.jpg'),
  Meal('Lunch', 'Grilled Chicken & Rice', '520 kcal', 'assets/images/nutrition/lunch.jpg'),
  Meal('Snack', 'Protein Shake', '280 kcal', 'assets/images/nutrition/protein_shake.jpg'),
  Meal('Dinner', 'Salmon, Quinoa, Vegetables', '630 kcal', 'assets/images/nutrition/dinner.jpg'),
];

const strengthPoints = [0.22, 0.30, 0.38, 0.43, 0.55, 0.62, 0.74, 0.82];
