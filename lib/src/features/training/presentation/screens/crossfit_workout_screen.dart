import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/figma_v1_tokens.dart';
import '../../../../core/widgets/page_shell.dart';
import '../../application/controllers/crossfit_session_controller.dart';
import '../../domain/entities/crossfit.dart';
import '../figma_score_counter.dart';
import 'mixed_session_screen.dart';
import 'workout_screen.dart';

class WorkoutEntryScreen extends ConsumerWidget {
  const WorkoutEntryScreen({super.key, required this.workoutId});
  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(workoutDetailProvider(workoutId));
    return detail.when(
      loading: () => const PageShell(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => PageShell(
        child: Text(error.toString()),
      ),
      data: (workout) {
        if (workout.isWodOnly) return CrossFitWorkoutScreen(workoutId: workoutId);
        if (workout.isMixedSession) return MixedSessionScreen(workoutId: workoutId);
        return WorkoutScreen(workoutId: workoutId);
      },
    );
  }
}

class CrossFitWorkoutScreen extends ConsumerWidget {
  const CrossFitWorkoutScreen({super.key, required this.workoutId});
  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(crossFitSessionControllerProvider(workoutId));

    return Theme(
      data: AppTheme.light,
      child: PageShell(
        maxWidth: 560,
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(error.toString(),
              style: const TextStyle(color: FigmaV1Tokens.danger)),
          data: (session) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.workout.title,
                key: const Key('wod-only-heading'),
                style: const TextStyle(
                  fontSize: 30,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: FigmaV1Tokens.text,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                session.workout.focus.isNotEmpty
                    ? session.workout.focus
                    : 'Coach-programmed · CrossFit',
                style: const TextStyle(color: FigmaV1Tokens.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              for (final block in session.workout.session!.blocks)
                if (block.wod != null && session.drafts[block.wod!.id] != null) ...[
                  _FigmaWodEntry(
                    key: ValueKey(block.wod!.id),
                    block: block,
                    draft: session.drafts[block.wod!.id]!,
                    onChanged: ({
                      ScalingLevel? scaling,
                      String? primary,
                      String? secondary,
                      List<LoadAttemptDraft>? loadAttempts,
                      String? unit,
                      bool? dnf,
                      double? rpe,
                      bool? clearRpe,
                      String? notes,
                    }) {
                      ref.read(
                        crossFitSessionControllerProvider(workoutId).notifier,
                      ).updateDraft(
                        block.wod!.id,
                        scaling: scaling,
                        primaryInput: primary,
                        secondaryInput: secondary,
                        loadAttempts: loadAttempts,
                        unit: unit,
                        dnf: dnf,
                        rpe: clearRpe == true ? null : rpe,
                        notes: notes,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              if (session.error != null) ...[
                Text(session.error!,
                    style: const TextStyle(
                      color: FigmaV1Tokens.danger,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 12),
              ],
              if (session.finished)
                const _SavedResult()
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    key: const Key('wod-save-result'),
                    onPressed: session.submitting
                        ? null
                        : () => _submit(context, ref),
                    style: FilledButton.styleFrom(
                      backgroundColor: FigmaV1Tokens.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      session.submitting ? 'Saving…' : 'Save WOD Result',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Result saved.')),
        );
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

class _SavedResult extends StatelessWidget {
  const _SavedResult();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      color: FigmaV1Tokens.successSurface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, color: FigmaV1Tokens.success),
        SizedBox(width: 8),
        Text('RESULT SAVED',
          style: TextStyle(
            color: FigmaV1Tokens.success,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

typedef _DraftChanged = void Function({
  ScalingLevel? scaling,
  String? primary,
  String? secondary,
  List<LoadAttemptDraft>? loadAttempts,
  String? unit,
  bool? dnf,
  double? rpe,
  bool? clearRpe,
  String? notes,
});

class _FigmaWodEntry extends StatelessWidget {
  const _FigmaWodEntry({
    super.key,
    required this.block,
    required this.draft,
    required this.onChanged,
  });

  final TrainingBlock block;
  final WodResultDraft draft;
  final _DraftChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final wod = block.wod!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${block.title} · ${_format(wod.format)}',
          style: const TextStyle(fontSize: 13, color: FigmaV1Tokens.muted),
        ),
        if (wod.scalingOptions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final option in wod.scalingOptions)
                ChoiceChip(
                  label: Text(option.name.toUpperCase()),
                  selected: draft.scaling == option,
                  onSelected: (selected) {
                    if (selected) onChanged(scaling: option);
                  },
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: draft.scaling == option
                        ? FigmaV1Tokens.success
                        : FigmaV1Tokens.muted,
                  ),
                  selectedColor: FigmaV1Tokens.successSurface,
                  backgroundColor: FigmaV1Tokens.surface,
                  side: BorderSide(
                    color: draft.scaling == option
                        ? FigmaV1Tokens.successSurface
                        : FigmaV1Tokens.border,
                  ),
                  showCheckmark: false,
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _V1Panel(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (block.coachNote != null) ...[
                Text(block.coachNote!,
                    style: const TextStyle(
                      color: FigmaV1Tokens.muted,
                      fontSize: 13,
                    )),
                const SizedBox(height: 12),
              ],
              ..._scoreFields(wod),
              if (wod.timeCapSeconds != null) ...[
                const SizedBox(height: 8),
                Text('Time cap ${_duration(wod.timeCapSeconds!)}',
                    style: const TextStyle(
                      color: FigmaV1Tokens.muted,
                      fontSize: 12,
                    )),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('DNF / time cap reached'),
                  value: draft.dnf,
                  onChanged: (value) => onChanged(dnf: value),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _V1Panel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Session feedback',
                  style: TextStyle(
                    color: FigmaV1Tokens.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 12),
              DropdownButtonFormField<double?>(
                initialValue: draft.rpe,
                decoration: const InputDecoration(labelText: 'RPE'),
                items: [
                  const DropdownMenuItem<double?>(
                    value: null, child: Text('Not set'),
                  ),
                  for (var value = 1; value <= 10; value++)
                    DropdownMenuItem<double?>(
                      value: value.toDouble(),
                      child: Text('RPE $value'),
                    ),
                ],
                onChanged: (value) => value == null
                    ? onChanged(clearRpe: true)
                    : onChanged(rpe: value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: draft.notes,
                key: ValueKey('wod-note-${wod.id}'),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'How did it feel?',
                ),
                onChanged: (value) => onChanged(notes: value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _scoreFields(WodDefinition wod) {
    Widget field(
      String label,
      String value,
      ValueChanged<String> update, {
      TextInputType? keyboard,
      double fontSize = 18,
      String? hint,
    }) => TextFormField(
      key: ValueKey('wod-score-${wod.id}-$label'),
      initialValue: value,
      keyboardType: keyboard ?? TextInputType.number,
      style: TextStyle(
        color: FigmaV1Tokens.text,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(labelText: label, hintText: hint),
      onChanged: update,
    );

    switch (wod.scoreType) {
      case WodScoreType.time:
        return [
          field(
            'Final time (mm:ss or seconds)',
            draft.primaryInput,
            (value) => onChanged(primary: value),
            fontSize: 38,
            hint: '00:00',
          ),
        ];
      case WodScoreType.roundsReps:
        return [
          field('Rounds', draft.primaryInput,
              (value) => onChanged(primary: value)),
          const SizedBox(height: 14),
          FigmaScoreCounter(
            label: 'Extra reps',
            value: int.tryParse(draft.secondaryInput) ?? 0,
            onChanged: (value) => onChanged(secondary: '$value'),
          ),
        ];
      case WodScoreType.load:
        return [
          field('Best load', draft.primaryInput,
              (value) => onChanged(primary: value),
              keyboard: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 10),
          _UnitField(draft: draft, onChanged: onChanged),
        ];
      case WodScoreType.reps:
        return [
          FigmaScoreCounter(
            label: 'Reps',
            value: int.tryParse(draft.primaryInput) ?? 0,
            onChanged: (value) => onChanged(primary: '$value'),
          ),
        ];
      case WodScoreType.calories:
        return [
          field('Calories', draft.primaryInput,
              (value) => onChanged(primary: value)),
        ];
      case WodScoreType.distance:
        return [
          field('Distance', draft.primaryInput,
              (value) => onChanged(primary: value),
              keyboard: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: const {'m', 'km', 'mi'}.contains(draft.unit)
                ? draft.unit : 'm',
            decoration: const InputDecoration(labelText: 'Distance unit'),
            items: const [
              DropdownMenuItem(value: 'm', child: Text('m')),
              DropdownMenuItem(value: 'km', child: Text('km')),
              DropdownMenuItem(value: 'mi', child: Text('mi')),
            ],
            onChanged: (unit) {
              if (unit != null) onChanged(unit: unit);
            },
          ),
        ];
      case WodScoreType.intervals:
        return [
          field('Interval scores (comma separated)', draft.primaryInput,
              (value) => onChanged(primary: value),
              keyboard: TextInputType.text),
        ];
      case WodScoreType.none:
        return const [
          Text('No numeric score required.',
              style: TextStyle(color: FigmaV1Tokens.muted)),
        ];
    }
  }
}

class _UnitField extends StatelessWidget {
  const _UnitField({required this.draft, required this.onChanged});
  final WodResultDraft draft;
  final _DraftChanged onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: const {'kg', 'lb'}.contains(draft.unit) ? draft.unit : 'kg',
    decoration: const InputDecoration(labelText: 'Unit'),
    items: const [
      DropdownMenuItem(value: 'kg', child: Text('kg')),
      DropdownMenuItem(value: 'lb', child: Text('lb')),
    ],
    onChanged: (unit) {
      if (unit != null) onChanged(unit: unit);
    },
  );
}

class _V1Panel extends StatelessWidget {
  const _V1Panel({required this.child, required this.padding});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: FigmaV1Tokens.surface,
      border: Border.all(color: FigmaV1Tokens.border),
      borderRadius: BorderRadius.circular(FigmaV1Tokens.cardRadius),
    ),
    child: child,
  );
}

String _format(WodFormat format) => switch (format) {
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
  WodFormat.custom => 'Custom',
};

String _duration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}
