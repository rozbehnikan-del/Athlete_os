import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../application/coach_providers.dart';
import 'create_workout_screen.dart';
import 'create_crossfit_session_screen.dart';
import 'coach_dashboard_view.dart';

String coachError(Object error) => error is AppException
    ? error.message
    : 'Could not load data. Please try again.';

class CoachHomeScreen extends StatelessWidget {
  const CoachHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const CoachDashboardView();
}

class CoachAthleteScreen extends ConsumerWidget {
  const CoachAthleteScreen({super.key, required this.athleteId});
  final String athleteId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Athlete Detail')),
    body: ref
        .watch(coachAthleteProvider(athleteId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(coachError(e)),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(coachAthleteProvider(athleteId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (detail) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                detail.athlete.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (detail.athlete.email != null) Text(detail.athlete.email!),
              for (final entry in detail.athlete.profile.entries.where(
                (e) => e.value != null,
              ))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${entry.key.replaceAll('_', ' ')}: ${entry.value}',
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create Workout'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CreateWorkoutScreen(athleteId: athleteId),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                icon: const Icon(Icons.sports_gymnastics_rounded),
                label: const Text('Build CrossFit Session'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        CreateCrossFitSessionScreen(athleteId: athleteId),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Today's assigned workout",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (detail.activeWorkout == null)
                const Text('No active workout today.')
              else
                Card(
                  child: ListTile(
                    title: Text('${detail.activeWorkout!['title']}'),
                    subtitle: Text(
                      [
                            detail.activeWorkout!['category'],
                            detail.activeWorkout!['focus'],
                            detail.activeWorkout!['scheduled_for'],
                          ]
                          .whereType<String>()
                          .where((s) => s.isNotEmpty)
                          .join(' • '),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Recent completed workouts',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (detail.recentWorkouts.isEmpty)
                const Text('No completed workouts yet.'),
              for (final workout in detail.recentWorkouts)
                Card(
                  child: ListTile(
                    title: Text('${workout['workout_title']}'),
                    subtitle: Text(
                      '${workout['completed_sets']}/${workout['total_sets']} sets • ${workout['completed_at']}',
                    ),
                  ),
                ),
            ],
          ),
        ),
  );
}
