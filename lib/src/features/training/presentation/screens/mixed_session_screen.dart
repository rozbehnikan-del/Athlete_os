import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/page_shell.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../application/controllers/crossfit_session_controller.dart';
import '../../application/controllers/mixed_session_controller.dart';
import '../../application/controllers/workout_session_controller.dart';
import '../../domain/entities/crossfit.dart';
import '../../domain/entities/exercise_prescription.dart';

class MixedSessionScreen extends ConsumerWidget {
  const MixedSessionScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(mixedSessionControllerProvider(workoutId));

    return PageShell(
      dark: true,
      child: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Text(error.toString(), style: const TextStyle(color: Colors.white)),
        data: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.workout.title,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mixed CrossFit session',
              style: TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: state.progress.clamp(0.0, 1.0).toDouble(),
              color: AppColors.primaryGreen,
              backgroundColor: Colors.white12,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 18),
            for (final exercise in state.workout.exercises) ...[
              _StrengthCard(
                exercise: exercise,
                drafts: state.setDrafts,
                onChanged: (key, {reps, weight, completed, rpe, clearRpe}) {
                  ref
                      .read(mixedSessionControllerProvider(workoutId).notifier)
                      .updateSetDraft(
                        key,
                        repsInput: reps,
                        weightInput: weight,
                        completed: completed,
                        rpe: clearRpe == true ? null : rpe,
                      );
                },
              ),
              const SizedBox(height: 12),
            ],
            for (final block in state.workout.session!.blocks) ...[
              if (block.wod != null)
                _WodCard(
                  wod: block.wod!,
                  title: block.title,
                  draft: state.wodDrafts[block.wod!.id]!,
                  onChanged: ({
                    ScalingLevel? scaling,
                    String? primary,
                    String? secondary,
                    String? unit,
                    bool? dnf,
                    double? rpe,
                    bool? clearRpe,
                    String? notes,
                  }) {
                    ref
                        .read(mixedSessionControllerProvider(workoutId).notifier)
                        .updateWodDraft(
                          block.wod!.id,
                          scaling: scaling,
                          primaryInput: primary,
                          secondaryInput: secondary,
                          unit: unit,
                          dnf: dnf,
                          rpe: clearRpe == true ? null : rpe,
                          notes: notes,
                        );
                  },
                ),
              if (block.wod != null) const SizedBox(height: 12),
            ],
            if (state.error != null) ...[
              Text(
                state.error!,
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (state.finished)
              const StatusBadge(
                label: 'SESSION SAVED',
                color: AppColors.primaryGreen,
                dark: true,
                icon: Icons.check_rounded,
              )
            else
              PrimaryButton(
                label: state.submitting ? 'Saving…' : 'Finish Session',
                icon: Icons.check_rounded,
                onPressed: state.submitting
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
          .read(mixedSessionControllerProvider(workoutId).notifier)
          .submit();
      if (saved && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mixed session saved.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save. Your entries are still here.'),
          ),
        );
      }
    }
  }
}

typedef _SetChanged = void Function(
  String key, {
  String? reps,
  String? weight,
  bool? completed,
  double? rpe,
  bool? clearRpe,
});

class _StrengthCard extends StatelessWidget {
  const _StrengthCard({
    required this.exercise,
    required this.drafts,
    required this.onChanged,
  });

  final ExercisePrescription exercise;
  final Map<String, SetResultDraft> drafts;
  final _SetChanged onChanged;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'STRENGTH',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            exercise.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (exercise.coachingNote != null) ...[
            const SizedBox(height: 6),
            Text(
              exercise.coachingNote!,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 14),
          for (final set in exercise.sets) ...[
            Builder(
              builder: (context) {
                final key = draftKey(exercise.id, set.setNumber);
                final draft = drafts[key]!;
                return Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: Text(
                            'Set ${set.setNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            initialValue: draft.repsInput,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Reps'),
                            onChanged: (value) => onChanged(key, reps: value),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            initialValue: draft.weightInput,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: draft.weightUnit?.name ?? 'Weight',
                            ),
                            onChanged: (value) => onChanged(key, weight: value),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<double?>(
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
                                ? onChanged(key, clearRpe: true)
                                : onChanged(key, rpe: value),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Completed',
                              style: TextStyle(color: Colors.white70),
                            ),
                            value: draft.completed,
                            onChanged: (value) =>
                                onChanged(key, completed: value ?? false),
                          ),
                        ),
                      ],
                    ),
                    if (set != exercise.sets.last)
                      const Divider(color: Colors.white12),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

typedef _WodChanged = void Function({
  ScalingLevel? scaling,
  String? primary,
  String? secondary,
  String? unit,
  bool? dnf,
  double? rpe,
  bool? clearRpe,
  String? notes,
});

class _WodCard extends StatelessWidget {
  const _WodCard({
    required this.wod,
    required this.title,
    required this.draft,
    required this.onChanged,
  });

  final WodDefinition wod;
  final String title;
  final WodResultDraft draft;
  final _WodChanged onChanged;

  @override
  Widget build(BuildContext context) {
    Widget field(
      String label,
      String value,
      ValueChanged<String> changed, {
      TextInputType? keyboard,
    }) {
      return TextFormField(
        initialValue: value,
        keyboardType: keyboard ?? TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label),
        onChanged: changed,
      );
    }

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
          const Text(
            'METCON / WOD',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
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
                if (value != null) onChanged(scaling: value);
              },
            ),
          const SizedBox(height: 10),
          ...switch (wod.scoreType) {
            WodScoreType.time => [
                field(
                  'Finish time (mm:ss or seconds)',
                  draft.primaryInput,
                  (value) => onChanged(primary: value),
                ),
              ],
            WodScoreType.roundsReps => [
                Row(
                  children: [
                    Expanded(
                      child: field(
                        'Rounds',
                        draft.primaryInput,
                        (value) => onChanged(primary: value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: field(
                        'Extra reps',
                        draft.secondaryInput,
                        (value) => onChanged(secondary: value),
                      ),
                    ),
                  ],
                ),
              ],
            WodScoreType.load => [
                Row(
                  children: [
                    Expanded(
                      child: field(
                        'Best load',
                        draft.primaryInput,
                        (value) => onChanged(primary: value),
                        keyboard:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue:
                            const {'kg', 'lb'}.contains(draft.unit)
                                ? draft.unit
                                : 'kg',
                        dropdownColor: AppColors.darkSurface,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: const [
                          DropdownMenuItem(value: 'kg', child: Text('kg')),
                          DropdownMenuItem(value: 'lb', child: Text('lb')),
                        ],
                        onChanged: (value) {
                          if (value != null) onChanged(unit: value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            WodScoreType.reps => [
                field(
                  'Reps',
                  draft.primaryInput,
                  (value) => onChanged(primary: value),
                ),
              ],
            WodScoreType.calories => [
                field(
                  'Calories',
                  draft.primaryInput,
                  (value) => onChanged(primary: value),
                ),
              ],
            WodScoreType.distance => [
                field(
                  'Distance',
                  draft.primaryInput,
                  (value) => onChanged(primary: value),
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
                    if (value != null) onChanged(unit: value);
                  },
                ),
              ],
            WodScoreType.intervals => [
                field(
                  'Interval scores (comma separated)',
                  draft.primaryInput,
                  (value) => onChanged(primary: value),
                  keyboard: TextInputType.text,
                ),
              ],
            WodScoreType.none => [
                const Text(
                  'No numeric score required.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
          },
          if (wod.timeCapSeconds != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'DNF / time cap reached',
                style: TextStyle(color: Colors.white),
              ),
              value: draft.dnf,
              onChanged: (value) => onChanged(dnf: value),
            ),
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
                ? onChanged(clearRpe: true)
                : onChanged(rpe: value),
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: draft.notes,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Athlete note'),
            onChanged: (value) => onChanged(notes: value),
          ),
        ],
      ),
    );
  }
}
