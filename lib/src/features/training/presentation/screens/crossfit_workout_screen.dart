import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/page_shell.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../application/controllers/crossfit_session_controller.dart';
import '../../domain/entities/crossfit.dart';
import '../../domain/entities/workout.dart';
import 'workout_screen.dart';

class WorkoutEntryScreen extends ConsumerWidget {
  const WorkoutEntryScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(workoutDetailProvider(workoutId));
    return detail.when(
      loading: () => const PageShell(
        dark: true,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => PageShell(
        dark: true,
        child: Text(error.toString(), style: const TextStyle(color: Colors.white)),
      ),
      data: (workout) {
        if (workout.isWodOnly) {
          return CrossFitWorkoutScreen(workoutId: workoutId);
        }
        if (workout.isMixedSession) {
          return PageShell(
            dark: true,
            child: _MixedSessionGuard(workout: workout),
          );
        }
        return WorkoutScreen(workoutId: workoutId);
      },
    );
  }
}

class _MixedSessionGuard extends StatelessWidget {
  const _MixedSessionGuard({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          workout.title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mixed session protected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'This session contains both set-based strength work and scored WODs. '
                'This app build will not submit only part of the session and mark the whole workout complete.',
                style: TextStyle(color: Colors.white70, height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CrossFitWorkoutScreen extends ConsumerWidget {
  const CrossFitWorkoutScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(crossFitSessionControllerProvider(workoutId));

    return PageShell(
      dark: true,
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Text(error.toString(), style: const TextStyle(color: Colors.white)),
        data: (session) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.workout.title,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coach-programmed CrossFit session',
              style: TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            for (final block in session.workout.session!.blocks) ...[
              _BlockCard(
                block: block,
                draft: block.wod == null
                    ? null
                    : session.drafts[block.wod!.id],
                onChanged: block.wod == null
                    ? null
                    : ({
                        ScalingLevel? scaling,
                        String? primary,
                        String? secondary,
                        String? unit,
                        bool? dnf,
                        double? rpe,
                        bool clearRpe = false,
                        String? notes,
                      }) {
                        ref
                            .read(
                              crossFitSessionControllerProvider(workoutId)
                                  .notifier,
                            )
                            .update(
                              block.wod!.id,
                              scaling: scaling,
                              primaryInput: primary,
                              secondaryInput: secondary,
                              unit: unit,
                              dnf: dnf,
                              rpe: clearRpe ? null : rpe,
                              notes: notes,
                            );
                      },
              ),
              const SizedBox(height: 12),
            ],
            if (session.error != null) ...[
              Text(
                session.error!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (session.finished)
              const StatusBadge(
                label: 'RESULT SAVED',
                color: AppColors.primaryGreen,
                dark: true,
                icon: Icons.check_rounded,
              )
            else
              PrimaryButton(
                label: session.submitting ? 'Saving…' : 'Save WOD Result',
                icon: Icons.check_rounded,
                onPressed: session.submitting
                    ? null
                    : () => _submit(context, ref),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    try {
      final saved = await ref
          .read(crossFitSessionControllerProvider(workoutId).notifier)
          .submit();
      if (saved && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Result saved.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save. Your score is still on screen.'),
          ),
        );
      }
    }
  }
}

typedef _DraftChanged = void Function({
  ScalingLevel? scaling,
  String? primary,
  String? secondary,
  String? unit,
  bool? dnf,
  double? rpe,
  bool clearRpe,
  String? notes,
});

class _BlockCard extends StatelessWidget {
  const _BlockCard({
    required this.block,
    required this.draft,
    required this.onChanged,
  });

  final TrainingBlock block;
  final WodResultDraft? draft;
  final _DraftChanged? onChanged;

  @override
  Widget build(BuildContext context) {
    final wod = block.wod;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            block.type.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            block.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (block.coachNote != null) ...[
            const SizedBox(height: 6),
            Text(
              block.coachNote!,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          if (wod != null && draft != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge(label: _formatLabel(wod.format), dark: true),
                StatusBadge(label: _scoreLabel(wod.scoreType), dark: true),
                if (wod.durationSeconds != null)
                  StatusBadge(
                    label: (wod.durationSeconds! ~/ 60).toString() + ' MIN',
                    dark: true,
                  ),
                if (wod.timeCapSeconds != null)
                  StatusBadge(
                    label: 'CAP ' + _duration(wod.timeCapSeconds!),
                    dark: true,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (wod.scalingOptions.isNotEmpty)
              DropdownButtonFormField<ScalingLevel>(
                initialValue: draft.scaling,
                dropdownColor: AppColors.darkSurface,
                decoration: const InputDecoration(labelText: 'Scaling'),
                items: [
                  for (final scaling in wod.scalingOptions)
                    DropdownMenuItem(
                      value: scaling,
                      child: Text(scaling.name.toUpperCase()),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) onChanged!(scaling: value);
                },
              ),
            const SizedBox(height: 12),
            ..._scoreFields(wod, draft),
            if (wod.timeCapSeconds != null) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'DNF / time cap reached',
                  style: TextStyle(color: Colors.white),
                ),
                value: draft.dnf,
                onChanged: (value) => onChanged!(dnf: value),
              ),
            ],
            const SizedBox(height: 8),
            DropdownButtonFormField<double?>(
              initialValue: draft.rpe,
              dropdownColor: AppColors.darkSurface,
              decoration: const InputDecoration(labelText: 'RPE'),
              items: [
                const DropdownMenuItem<double?>(
                  value: null,
                  child: Text('Not set'),
                ),
                for (var value = 1; value <= 10; value++)
                  DropdownMenuItem<double?>(
                    value: value.toDouble(),
                    child: Text(value.toString()),
                  ),
              ],
              onChanged: (value) => value == null
                  ? onChanged!(clearRpe: true)
                  : onChanged!(rpe: value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: draft.notes,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Athlete note'),
              onChanged: (value) => onChanged!(notes: value),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _scoreFields(WodDefinition wod, WodResultDraft draft) {
    Widget field(
      String label,
      String initial,
      ValueChanged<String> changed, {
      TextInputType? keyboard,
    }) =>
        TextFormField(
          initialValue: initial,
          keyboardType: keyboard ?? TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(labelText: label),
          onChanged: changed,
        );

    switch (wod.scoreType) {
      case WodScoreType.time:
        return [
          field(
            'Finish time (mm:ss or seconds)',
            draft.primaryInput,
            (value) => onChanged!(primary: value),
          ),
        ];
      case WodScoreType.roundsReps:
        return [
          Row(
            children: [
              Expanded(
                child: field(
                  'Rounds',
                  draft.primaryInput,
                  (value) => onChanged!(primary: value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: field(
                  'Extra reps',
                  draft.secondaryInput,
                  (value) => onChanged!(secondary: value),
                ),
              ),
            ],
          ),
        ];
      case WodScoreType.load:
        return [
          Row(
            children: [
              Expanded(
                child: field(
                  'Best load',
                  draft.primaryInput,
                  (value) => onChanged!(primary: value),
                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _UnitPicker(draft: draft, onChanged: onChanged!)),
            ],
          ),
        ];
      case WodScoreType.reps:
        return [
          field('Reps', draft.primaryInput, (value) => onChanged!(primary: value)),
        ];
      case WodScoreType.calories:
        return [
          field(
            'Calories',
            draft.primaryInput,
            (value) => onChanged!(primary: value),
          ),
        ];
      case WodScoreType.distance:
        return [
          field(
            'Distance',
            draft.primaryInput,
            (value) => onChanged!(primary: value),
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: const {'m', 'km', 'mi'}.contains(draft.unit)
                ? draft.unit
                : 'm',
            dropdownColor: AppColors.darkSurface,
            decoration: const InputDecoration(labelText: 'Distance unit'),
            items: const [
              DropdownMenuItem(value: 'm', child: Text('m')),
              DropdownMenuItem(value: 'km', child: Text('km')),
              DropdownMenuItem(value: 'mi', child: Text('mi')),
            ],
            onChanged: (value) {
              if (value != null) onChanged!(unit: value);
            },
          ),
        ];
      case WodScoreType.intervals:
        return [
          field(
            'Interval scores (comma separated)',
            draft.primaryInput,
            (value) => onChanged!(primary: value),
            keyboard: TextInputType.text,
          ),
        ];
      case WodScoreType.none:
        return const [
          Text(
            'No numeric score required.',
            style: TextStyle(color: Colors.white70),
          ),
        ];
    }
  }

  static String _formatLabel(WodFormat format) => switch (format) {
    WodFormat.forTime => 'FOR TIME',
    WodFormat.amrap => 'AMRAP',
    WodFormat.emom => 'EMOM',
    WodFormat.roundsForTime => 'ROUNDS FOR TIME',
    WodFormat.chipper => 'CHIPPER',
    WodFormat.intervals => 'INTERVALS',
    WodFormat.maxLoad => 'MAX LOAD',
    WodFormat.maxReps => 'MAX REPS',
    WodFormat.calories => 'CALORIES',
    WodFormat.distance => 'DISTANCE',
    WodFormat.tabata => 'TABATA',
    WodFormat.custom => 'CUSTOM',
  };

  static String _scoreLabel(WodScoreType type) => switch (type) {
    WodScoreType.time => 'TIME',
    WodScoreType.roundsReps => 'ROUNDS + REPS',
    WodScoreType.load => 'LOAD',
    WodScoreType.reps => 'REPS',
    WodScoreType.calories => 'CALORIES',
    WodScoreType.distance => 'DISTANCE',
    WodScoreType.intervals => 'INTERVALS',
    WodScoreType.none => 'NO SCORE',
  };

  static String _duration(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return minutes.toString() + ':' + rest.toString().padLeft(2, '0');
  }
}

class _UnitPicker extends StatelessWidget {
  const _UnitPicker({required this.draft, required this.onChanged});

  final WodResultDraft draft;
  final _DraftChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final value = const {'kg', 'lb'}.contains(draft.unit) ? draft.unit : 'kg';
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AppColors.darkSurface,
      decoration: const InputDecoration(labelText: 'Unit'),
      items: const [
        DropdownMenuItem(value: 'kg', child: Text('kg')),
        DropdownMenuItem(value: 'lb', child: Text('lb')),
      ],
      onChanged: (value) {
        if (value != null) onChanged(unit: value);
      },
    );
  }
}
