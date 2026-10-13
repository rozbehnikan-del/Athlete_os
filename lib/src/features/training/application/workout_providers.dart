import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/mock_workout_repository.dart';
import '../domain/repositories/workout_repository.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => MockWorkoutRepository(),
);
