import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/page_shell.dart';
import '../../../training/application/controllers/workout_controller.dart';
import '../../domain/progress_metrics.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PageShell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.progress,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),
        ref
            .watch(workoutHistoryProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Column(
                children: [
                  const Text('Could not load workout history.'),
                  TextButton(
                    onPressed: () => ref.invalidate(workoutHistoryProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
              data: (history) {
                if (history.isEmpty) {
                  return const Text(
                    'Complete your first workout to see your progress.',
                  );
                }
                final metrics = ProgressMetrics(history);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${metrics.totalWorkouts} completed workouts'),
                    Text('${metrics.completedSets} completed sets'),
                    Text('${metrics.prescribedSets} prescribed sets'),
                    Text('Overall ${metrics.completion.label}'),
                    const Text('Grades measure prescription completion.'),
                    if (metrics.recentChange != null)
                      Text(
                        'Recent completion change: ${metrics.recentChange! >= 0 ? '+' : ''}${metrics.recentChange!.toStringAsFixed(1)} percentage points (last 3 vs previous 3 workouts)',
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Recent workout activity',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    for (final entry in history.take(10))
                      Card(
                        child: ListTile(
                          title: Text(entry.workoutTitle),
                          subtitle: Text(
                            '${entry.completedAt.toLocal().toString().split('.').first}\n${entry.completedSets}/${entry.totalSets} sets\n${entry.completion.label}',
                          ),
                          isThreeLine: true,
                        ),
                      ),
                  ],
                );
              },
            ),
      ],
    ),
  );
}
