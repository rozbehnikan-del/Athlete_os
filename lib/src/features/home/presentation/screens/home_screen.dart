import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/athlete_avatar.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/widgets/page_shell.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../../core/widgets/responsive_grid.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../app/router/routes.dart';
import '../../../training/application/controllers/workout_controller.dart';
import '../../../training/domain/entities/workout.dart';
import '../../../training/domain/entities/exercise_prescription.dart';
import '../../../training/presentation/training_formatters.dart';
import '../../../auth/application/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider).asData?.value;
    final wide = windowClassOf(context) != WindowClass.compact;
    return PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AthleteAvatar(
                label: user == null || user.fullName.isEmpty
                    ? ''
                    : user.fullName.substring(0, 1),
                size: 58,
                showBorder: false,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.goodMorning,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      user?.fullName ?? '',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontSize: 28, height: 1.05),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _DateSelector(),
          const SizedBox(height: 18),
          const _TodayWorkoutCard(),
          const SizedBox(height: 26),
          ResponsiveGrid(
            columns: wide ? 3 : 3,
            children: [
              MetricCard(
                title: l.nutrition,
                value: '1,850 kcal',
                icon: Icons.local_fire_department_rounded,
              ),
              MetricCard(
                title: l.weight,
                value: '78.5 kg',
                delta: '-2.1 kg',
                icon: Icons.monitor_weight_rounded,
              ),
              MetricCard(
                title: l.sleep,
                value: '7h 12m',
                icon: Icons.bedtime_rounded,
              ),
            ],
          ),
          if (wide) ...[const SizedBox(height: 18), const _ReadinessCard()],
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector();

  @override
  Widget build(BuildContext context) {
    final days = [
      'Mon\n13',
      'Tue\n14',
      'Wed\n15',
      'Thu\n16',
      'Fri\n17',
      'Sat\n18',
    ];
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (_, i) => Container(
          width: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: i == 2
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            days[i],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: i == 2
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayWorkoutCard extends ConsumerWidget {
  const _TodayWorkoutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final workout = ref.watch(workoutControllerProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: workout.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Text('$error', style: const TextStyle(color: AppColors.red)),
        data: (workout) => workout == null
            ? Text(
                'No active workout today',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.todaysWorkout,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (_workoutMetadata(workout).isNotEmpty)
                              Text(
                                _workoutMetadata(workout),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          l.viewPlan,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            for (var i = 0; i < workout.exercises.length; i++)
                              _ExerciseLine(
                                exercise: workout.exercises[i],
                                complete: i == 0,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const ProgressRing(value: .75, size: 58),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: l.startWorkout,
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () =>
                          context.go(AppRoutes.workoutPath(workout.id)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

String _workoutMetadata(Workout workout) {
  final category = workout.category.trim();
  final focus = workout.focus.trim();
  if (category.isEmpty) {
    return focus;
  }
  if (focus.isEmpty) {
    return category;
  }
  return '$category ($focus)';
}

class _ExerciseLine extends StatelessWidget {
  const _ExerciseLine({required this.exercise, this.complete = false});

  final ExercisePrescription exercise;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Image.asset(
                exerciseImagePath(exercise.exerciseSlug),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  exercisePrescriptionDetail(exercise),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            complete
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: complete
                ? AppColors.primaryGreen
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l.readiness,
            trailing: const ProgressRing(value: .82),
          ),
          const SizedBox(height: 18),
          for (final item in ['Sleep', 'Energy', 'Soreness', 'Stress', 'Pain'])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const StatusBadge(label: 'Good'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
