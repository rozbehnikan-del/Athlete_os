import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/api_progress_repository.dart';
import '../domain/progress_repository.dart';
import '../domain/progress_summary.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  ref.watch(authControllerProvider.select((s) => s.asData?.value?.id));
  return ApiProgressRepository(ref.watch(apiClientProvider));
});
final progressSummaryProvider = FutureProvider<ProgressSummary>(
  (ref) => ref.watch(progressRepositoryProvider).getSummary(),
);
