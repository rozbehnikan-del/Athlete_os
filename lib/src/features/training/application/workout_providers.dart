import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/repositories/api_workout_repository.dart';
import '../domain/repositories/workout_repository.dart';

export '../../../core/api/api_providers.dart'
    show apiClientProvider, apiConfigProvider;

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  // Recreate Training state when the authenticated account changes.
  ref.watch(authControllerProvider.select((auth) => auth.asData?.value?.id));
  return ApiWorkoutRepository(ref.watch(apiClientProvider));
});
