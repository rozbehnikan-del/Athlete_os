import 'dart:async';

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
import '../../domain/entities/wod_timer.dart';

class MixedSessionScreen extends ConsumerStatefulWidget {
  const MixedSessionScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  ConsumerState<MixedSessionScreen> createState() => _MixedSessionScreenState();
}

class _MixedSessionScreenState extends ConsumerState<MixedSessionScreen> {
  Timer? _timer;
  String? _activeWodId;
  final Map<String, Stopwatch> _wodClocks = {};

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(mixedSessionControllerProvider(widget.workoutId));

    return PageShell(
      dark: true,
      child: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Text(error.toString(), style: const TextStyle(color: Colors.white)),
        data: (state) {
          final block = state.currentBlock;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.workout.title,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Block ${state.currentBlockIndex + 1} of ${state.blocks.length}',
                style: const TextStyle(
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
              const SizedBox(height: 14),
              _BlockStrip(
                blocks: state.blocks,
                currentIndex: state.currentBlockIndex,
                completedIds: state.completedBlockIds,
                onSelected: (index) {
                  _pauseTimer();
                  ref
                      .read(
                        mixedSessionControllerProvider(widget.workoutId).notifier,
                      )
                      .goToBlock(index);
                },
              ),
              const SizedBox(height: 18),
              _BlockHeader(block: block),
              const SizedBox(height: 14),
              if (block.type == TrainingBlockType.strength)
                for (final exercise in state.workout.exercises) ...[
                  _StrengthCard(
                    exercise: exercise,
                    drafts: state.setDrafts,
                    onChanged: (
                      key, {
                      reps,
                      weight,
                      completed,
                      rpe,
                      clearRpe,
                    }) {
                      ref
                          .read(
                            mixedSessionControllerProvider(widget.workoutId)
                                .notifier,
                          )
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
                ]
              else if (block.wod != null)
                _WodCard(
                  wod: block.wod!,
                  title: block.title,
                  draft: state.wodDrafts[block.wod!.id]!,
                  timerDisplay: WodTimerReading.forWod(
                    block.wod!,
                    _wodClocks[block.wod!.id]?.elapsed ?? Duration.zero,
                  ),
                  timerRunning: _activeWodId == block.wod!.id && _timer != null,
                  onStartTimer: () => _startTimer(block.wod!),
                  onPauseTimer: _pauseTimer,
                  onResetTimer: () => _resetTimer(block.wod!),
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
                    ref
                        .read(
                          mixedSessionControllerProvider(widget.workoutId)
                              .notifier,
                        )
                        .updateWodDraft(
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
                )
              else
                _InstructionCard(block: block),
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.error!,
                  style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (state.finished)
                const StatusBadge(
                  label: 'SESSION SAVED',
                  color: AppColors.primaryGreen,
                  dark: true,
                  icon: Icons.check_rounded,
                )
              else
                Row(
                  children: [
                    if (!state.isFirstBlock) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: state.submitting
                              ? null
                              : () {
                                  _pauseTimer();
                                  ref
                                      .read(
                                        mixedSessionControllerProvider(
                                          widget.workoutId,
                                        ).notifier,
                                      )
                                      .previousBlock();
                                },
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: state.isLastBlock
                          ? PrimaryButton(
                              label:
                                  state.submitting ? 'Saving…' : 'Finish Session',
                              icon: Icons.check_rounded,
                              onPressed: state.submitting
                                  ? null
                                  : () => _finish(context),
                            )
                          : PrimaryButton(
                              label: state.completedBlockIds.contains(block.id)
                                  ? 'Next Block'
                                  : 'Complete & Continue',
                              icon: Icons.arrow_forward_rounded,
                              onPressed: state.submitting
                                  ? null
                                  : () {
                                      _pauseTimer();
                                      ref
                                          .read(
                                            mixedSessionControllerProvider(
                                              widget.workoutId,
                                            ).notifier,
                                          )
                                          .completeCurrentBlockAndContinue();
                                    },
                            ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  void _startTimer(WodDefinition wod) {
    _pauseTimer();
    final clock = _wodClocks.putIfAbsent(wod.id, Stopwatch.new);
    if (WodTimerReading.forWod(wod, clock.elapsed)?.ended ?? false) {
      clock.reset();
    }
    clock.start();
    _activeWodId = wod.id;
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      if (WodTimerReading.forWod(wod, clock.elapsed)?.ended ?? false) {
        _pauseTimer();
      } else {
        setState(() {});
      }
    });
    setState(() {});
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    if (_activeWodId != null) {
      _wodClocks[_activeWodId]?.stop();
    }
    if (mounted) setState(() {});
  }

  void _resetTimer(WodDefinition wod) {
    _pauseTimer();
    _activeWodId = wod.id;
    _wodClocks[wod.id]?.reset();
    if (mounted) setState(() {});
  }

  Future<void> _finish(BuildContext context) async {
    _pauseTimer();
    try {
      final saved = await ref
          .read(
            mixedSessionControllerProvider(widget.workoutId).notifier,
          )
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

class _BlockStrip extends StatelessWidget {
  const _BlockStrip({
    required this.blocks,
    required this.currentIndex,
    required this.completedIds,
    required this.onSelected,
  });

  final List<TrainingBlock> blocks;
  final int currentIndex;
  final Set<String> completedIds;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < blocks.length; index++) ...[
            ChoiceChip(
              selected: currentIndex == index,
              onSelected: (_) => onSelected(index),
              avatar: completedIds.contains(blocks[index].id)
                  ? const Icon(Icons.check_rounded, size: 16)
                  : null,
              label: Text(
                '${index + 1}. ${_blockTypeLabel(blocks[index].type)}',
              ),
            ),
            if (index != blocks.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _BlockHeader extends StatelessWidget {
  const _BlockHeader({required this.block});

  final TrainingBlock block;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(_blockIcon(block.type), color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _blockTypeLabel(block.type).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                block.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (block.coachNote != null)
                Text(
                  block.coachNote!,
                  style: const TextStyle(color: Colors.white70),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.block});

  final TrainingBlock block;

  @override
  Widget build(BuildContext context) {
    final prescription = block.prescription;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: prescription.isEmpty
          ? const Text(
              'Follow the coach instructions for this block.',
              style: TextStyle(color: Colors.white70),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in prescription.entries) ...[
                  Text(
                    _prettyKey(entry.key),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _PrescriptionValue(value: entry.value),
                  const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }
}

class _PrescriptionValue extends StatelessWidget {
  const _PrescriptionValue({required this.value});

  final Object? value;

  @override
  Widget build(BuildContext context) {
    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in value as List)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                item is Map
                    ? item.entries
                        .map((entry) => '${entry.key}: ${entry.value}')
                        .join('  •  ')
                    : '• $item',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      );
    }
    return Text(
      '$value',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
    );
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
  List<LoadAttemptDraft>? loadAttempts,
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
    required this.timerDisplay,
    required this.timerRunning,
    required this.onStartTimer,
    required this.onPauseTimer,
    required this.onResetTimer,
    required this.onChanged,
  });

  final WodDefinition wod;
  final String title;
  final WodResultDraft draft;
  final WodTimerReading? timerDisplay;
  final bool timerRunning;
  final VoidCallback onStartTimer;
  final VoidCallback onPauseTimer;
  final VoidCallback onResetTimer;
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
          if (timerDisplay != null) ...[
            _TimerPanel(
              reading: timerDisplay!,
              running: timerRunning,
              onStart: onStartTimer,
              onPause: onPauseTimer,
              onReset: onResetTimer,
            ),
            const SizedBox(height: 16),
          ],
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
                if (wod.format == WodFormat.maxLoad)
                  _MaxLoadAttempts(
                    draft: draft,
                    onChanged: (attempts) => onChanged(loadAttempts: attempts),
                    onUnitChanged: (unit) => onChanged(unit: unit),
                  )
                else
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
                        initialValue: const {'kg', 'lb'}.contains(draft.unit)
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

class _MaxLoadAttempts extends StatelessWidget {
  const _MaxLoadAttempts({
    required this.draft,
    required this.onChanged,
    required this.onUnitChanged,
  });

  final WodResultDraft draft;
  final ValueChanged<List<LoadAttemptDraft>> onChanged;
  final ValueChanged<String> onUnitChanged;

  void _update(int index, LoadAttemptDraft updated) {
    final next = List<LoadAttemptDraft>.of(draft.loadAttempts);
    next[index] = updated;
    onChanged(List.unmodifiable(next));
  }

  @override
  Widget build(BuildContext context) {
    final successful = draft.loadAttempts
        .where((attempt) => attempt.successful)
        .map((attempt) => double.tryParse(attempt.loadInput))
        .whereType<double>()
        .where((load) => load.isFinite && load > 0)
        .toList();
    final best = successful.isEmpty
        ? null
        : successful.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'MAX LOAD ATTEMPTS',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(
              width: 90,
              child: DropdownButtonFormField<String>(
                initialValue: const {'kg', 'lb'}.contains(draft.unit) ? draft.unit : 'kg',
                decoration: const InputDecoration(labelText: 'Unit'),
                dropdownColor: AppColors.darkSurface,
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'lb', child: Text('lb')),
                ],
                onChanged: (unit) {
                  if (unit != null) onUnitChanged(unit);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < draft.loadAttempts.length; index++) ...[
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('load-attempt-' + draft.loadAttempts[index].id),
                  initialValue: draft.loadAttempts[index].loadInput,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: 'Attempt ' +
                      (index + 1).toString() + ' (' + draft.unit + ')'),
                  onChanged: (input) => _update(
                    index,
                    draft.loadAttempts[index].copyWith(loadInput: input),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Successful lift',
                child: Checkbox(
                  value: draft.loadAttempts[index].successful,
                  onChanged: (success) => _update(
                    index,
                    draft.loadAttempts[index].copyWith(successful: success ?? false),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove attempt',
                onPressed: () => onChanged([
                  for (var i = 0; i < draft.loadAttempts.length; i++)
                    if (i != index) draft.loadAttempts[i],
                ]),
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextButton.icon(
          onPressed: draft.loadAttempts.length >= 30
              ? null
              : () => onChanged([
                  ...draft.loadAttempts,
                  LoadAttemptDraft(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                  ),
                ]),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add attempt'),
        ),
        Text(
          best == null
              ? 'Record a successful attempt to set a best load.'
              : 'Best successful load: ' + best.toString() + ' ' + draft.unit,
          style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _TimerPanel extends StatelessWidget {
  const _TimerPanel({
    required this.reading,
    required this.running,
    required this.onStart,
    required this.onPause,
    required this.onReset,
  });

  final WodTimerReading reading;
  final bool running;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final minutes = reading.seconds ~/ 60;
    final remainder = reading.seconds % 60;
    final label = reading.emomMinute == null
        ? (reading.countsUp ? 'ELAPSED' : 'REMAINING')
        : 'EMOM • MINUTE ${reading.emomMinute} / ${reading.emomTotalMinutes}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$minutes:${remainder.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              if (reading.ended)
                const Text(
                  'TIME CAP REACHED',
                  style: TextStyle(color: AppColors.red, fontSize: 12),
                ),
            ],
          ),
          const Spacer(),
          IconButton.filledTonal(
            tooltip: reading.ended ? 'Reset to restart' : running ? 'Pause' : 'Start',
            onPressed: reading.ended ? null : running ? onPause : onStart,
            icon: Icon(
              running ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: 'Reset',
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
    );
  }
}

String _blockTypeLabel(TrainingBlockType type) => switch (type) {
  TrainingBlockType.warmup => 'Warm-up',
  TrainingBlockType.strength => 'Strength',
  TrainingBlockType.skill => 'Skill',
  TrainingBlockType.metcon => 'Metcon',
  TrainingBlockType.accessory => 'Accessory',
};

IconData _blockIcon(TrainingBlockType type) => switch (type) {
  TrainingBlockType.warmup => Icons.local_fire_department_rounded,
  TrainingBlockType.strength => Icons.fitness_center_rounded,
  TrainingBlockType.skill => Icons.auto_awesome_rounded,
  TrainingBlockType.metcon => Icons.timer_rounded,
  TrainingBlockType.accessory => Icons.self_improvement_rounded,
};

String _prettyKey(String value) {
  final words = value
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .toList();
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
