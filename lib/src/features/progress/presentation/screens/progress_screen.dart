import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/page_shell.dart';
import '../../application/progress_providers.dart';
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
            .watch(progressSummaryProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Column(
                children: [
                  const Text('Could not load workout history.'),
                  TextButton(
                    onPressed: () => ref.invalidate(progressSummaryProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
              data: (summary) {
                if (summary.totalWorkouts == 0) {
                  return const Text(
                    'Complete your first workout to see your progress.',
                  );
                }
                final metrics = ProgressMetrics(summary.recentActivity);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${summary.totalWorkouts} completed workouts'),
                    Text('${summary.completedSets} completed sets'),
                    Text('${summary.prescribedSets} prescribed sets'),
                    Text('Overall ${summary.completion.label}'),
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
                    for (final entry in summary.recentActivity)
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
