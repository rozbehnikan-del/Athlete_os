import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/theme/figma_v1_tokens.dart';
import '../../application/controllers/workout_controller.dart';
import '../../domain/entities/crossfit.dart';
import '../../domain/entities/workout.dart';
import '../training_formatters.dart';

/// Training overview: Figma CrossFit V1 / Athlete Mobile, node 2:41.
class FigmaTrainingOverview extends ConsumerWidget {
  const FigmaTrainingOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workoutControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Could not load today’s training.'),
          TextButton(
            onPressed: () => ref.invalidate(workoutControllerProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
      data: (workout) => workout == null
          ? const Text('No active workout today')
          : FigmaTrainingBlockList(workout: workout),
    );
  }
}

/// A pure, data-driven list so layout can be checked without backend requests.
class FigmaTrainingBlockList extends StatelessWidget {
  const FigmaTrainingBlockList({super.key, required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final entries = _overviewEntries(workout);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coach programmed',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 18),
        for (final entry in entries) ...[
          _TrainingBlockCard(entry: entry),
          const SizedBox(height: 18),
        ],
        if (entries.isEmpty) ...[
          Text(
            workout.title,
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 18),
        ],
        SizedBox(
          key: const Key('training-start-workout'),
          width: double.infinity,
          height: FigmaV1Tokens.primaryButtonHeight,
          child: FilledButton(
            onPressed: () => context.go(AppRoutes.workoutPath(workout.id)),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  FigmaV1Tokens.primaryButtonRadius,
                ),
              ),
            ),
            child: const Text(
              'Start Workout',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _BlockOverview {
  const _BlockOverview(this.label, this.title, this.detail);

  final String label;
  final String title;
  final String detail;
}

List<_BlockOverview> _overviewEntries(Workout workout) {
  final blocks = workout.session?.blocks;
  if (blocks == null || blocks.isEmpty) {
    return [
      for (final exercise in workout.exercises)
        _BlockOverview('STRENGTH', exercise.name,
            exercisePrescriptionDetail(exercise)),
    ];
  }
  final entries = <_BlockOverview>[];
  for (final block in blocks) {
    final label = block.type.name.toUpperCase().replaceAll('WARMUP', 'WARM-UP');
    var title = block.title;
    var detail = '';
    if (block.type == TrainingBlockType.strength &&
        workout.exercises.isNotEmpty) {
      final exercise = workout.exercises.first;
      title = exercise.name;
      detail = exercisePrescriptionDetail(exercise);
    } else if (block.wod != null) {
      final wod = block.wod!;
      final format = switch (wod.format) {
        WodFormat.forTime => 'For Time',
        WodFormat.amrap => 'AMRAP',
        WodFormat.emom => 'EMOM',
        WodFormat.roundsForTime => 'Rounds for Time',
        WodFormat.chipper => 'Chipper',
        WodFormat.intervals => 'Intervals',
        WodFormat.maxLoad => 'Max Load',
        WodFormat.maxReps => 'Max Reps',
        WodFormat.calories => 'Calories',
        WodFormat.distance => 'Distance',
        WodFormat.tabata => 'Tabata',
        WodFormat.custom => 'WOD',
      };
      final minutes = wod.durationSeconds == null
          ? ''
          : ' ${wod.durationSeconds! ~/ 60}';
      title = '$format$minutes';
      detail = block.title == title ? '' : block.title;
    }
    if (detail.isEmpty) {
      for (final key in ['description', 'details', 'instructions', 'movements']) {
        final value = block.prescription[key];
        if (value is String && value.trim().isNotEmpty) {
          detail = value.trim();
          break;
        }
        if (value is List && value.isNotEmpty) {
          detail = value.join(' · ');
          break;
        }
      }
    }
    if (detail.isEmpty && block.coachNote != null) {
      detail = block.coachNote!;
    }
    entries.add(_BlockOverview(label, title, detail));
  }
  return entries;
}

class _TrainingBlockCard extends StatelessWidget {
  const _TrainingBlockCard({required this.entry});

  final _BlockOverview entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(FigmaV1Tokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.title,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 18,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (entry.detail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.detail,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
