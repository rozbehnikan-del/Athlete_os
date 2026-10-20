import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/api_coach_repository.dart';
import '../domain/coach_repository.dart';
import '../domain/coach_models.dart';

final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  ref.watch(authControllerProvider.select((s) => s.asData?.value?.id));
  return ApiCoachRepository(ref.watch(apiClientProvider));
});
final coachRosterProvider = FutureProvider<List<CoachAthlete>>(
  (ref) => ref.watch(coachRepositoryProvider).getAthletes(),
);
final coachAthleteProvider = FutureProvider.autoDispose
    .family<AthleteTrainingDetail, String>(
      (ref, id) => ref.watch(coachRepositoryProvider).getAthlete(id),
    );
final exerciseLibraryProvider = FutureProvider<List<LibraryExercise>>(
  (ref) => ref.watch(coachRepositoryProvider).getExercises(),
);
