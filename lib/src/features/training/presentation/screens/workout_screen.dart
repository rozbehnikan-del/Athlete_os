import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/page_shell.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/tab_selector.dart';
import '../../application/controllers/workout_controller.dart';
import '../../domain/entities/exercise_set.dart';
import '../training_formatters.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final workout = ref.watch(workoutControllerProvider);
    return PageShell(
      dark: true,
      child: workout.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Text('$error', style: const TextStyle(color: Colors.white)),
        data: (workout) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.backSquat,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 14),
            TabSelector(
              labels: [l.overview, l.history, l.video, l.notes],
              dark: true,
            ),
            const SizedBox(height: 18),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: Image(
                      image: AssetImage(
                        'assets/images/exercises/back_squat_hero.jpg',
                      ),
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: .20),
                    ),
                  ),
                  Center(
                    child: IconButton.filled(
                      onPressed: () {},
                      icon: const Icon(Icons.play_arrow_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: AppColors.brandBlack,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        StatusBadge(label: l.strength, dark: true),
                        StatusBadge(label: l.compound, dark: true),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 58,
                    child: Text(
                      l.backSquat,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              children: [
                StatusBadge(
                  label: l.coachControlled,
                  color: AppColors.amber,
                  dark: true,
                  icon: Icons.lock_rounded,
                ),
                StatusBadge(
                  label: l.verified,
                  dark: true,
                  icon: Icons.verified_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(l.set, style: _tableHead)),
                      Expanded(child: Text(l.reps, style: _tableHead)),
                      Expanded(child: Text(l.weight, style: _tableHead)),
                      const SizedBox(width: 34),
                    ],
                  ),
                  const Divider(color: Colors.white12),
                  for (final set in workout.exercises.first.sets)
                    _WorkoutSetRow(set: set),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: SecondaryButton(label: l.addSet, dark: true)),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: l.completeSet,
                    icon: Icons.check_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const _tableHead = TextStyle(
  color: Colors.white54,
  fontWeight: FontWeight.w800,
);

class _WorkoutSetRow extends StatelessWidget {
  const _WorkoutSetRow({required this.set});

  final ExerciseSet set;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${set.setNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${set.targetReps}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              targetWeightLabel(set),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Icon(
            set.completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: set.completed ? AppColors.primaryGreen : Colors.white24,
          ),
        ],
      ),
    );
  }
}
