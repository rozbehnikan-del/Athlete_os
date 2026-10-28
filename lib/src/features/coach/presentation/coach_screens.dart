import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/application/app_theme_controller.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../application/coach_providers.dart';
import 'create_workout_screen.dart';
import 'create_crossfit_session_screen.dart';

String coachError(Object error) => error is AppException
    ? error.message
    : 'Could not load data. Please try again.';

class CoachHomeScreen extends ConsumerWidget {
  const CoachHomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Home'),
        actions: [
          PopupMenuButton<ThemeMode>(
            tooltip: 'Appearance',
            icon: const Icon(Icons.brightness_6_outlined),
            onSelected: (mode) => ref
                .read(appThemeControllerProvider.notifier)
                .setThemeMode(mode),
            itemBuilder: (_) => [
              for (final mode in ThemeMode.values)
                PopupMenuItem(value: mode, child: Text(mode.name)),
            ],
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(coachRosterProvider);
          await ref.read(coachRosterProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              user?.fullName ?? '',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ref
                .watch(coachRosterProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Column(
                    children: [
                      Text(coachError(e)),
                      TextButton(
                        onPressed: () => ref.invalidate(coachRosterProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                  data: (athletes) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Athletes (${athletes.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (athletes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text('No athletes assigned yet.'),
                        ),
                      for (final athlete in athletes)
                        Card(
                          child: ListTile(
                            title: Text(athlete.name),
                            subtitle: Text(
                              [
                                if (athlete.email != null) athlete.email!,
                                if (athlete.profile['experience_level'] != null)
                                  '${athlete.profile['experience_level']}',
                              ].join(' • '),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () =>
                                context.push('/coach/athletes/${athlete.id}'),
                          ),
                        ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
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
