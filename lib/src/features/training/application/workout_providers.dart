import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import '../data/repositories/api_workout_repository.dart';
import '../domain/repositories/workout_repository.dart';

final apiConfigProvider = Provider<ApiConfig>((ref) => const ApiConfig());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(config: ref.watch(apiConfigProvider)),
);

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => ApiWorkoutRepository(ref.watch(apiClientProvider)),
);
