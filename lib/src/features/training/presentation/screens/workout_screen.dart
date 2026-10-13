import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/page_shell.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/surface_decoration.dart';
import '../../../../core/widgets/tab_selector.dart';
import '../../application/controllers/workout_controller.dart';
import '../../application/controllers/workout_session_controller.dart';
import '../../domain/entities/workout_history_entry.dart';
import '../training_formatters.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key, this.workoutId, this.initialHistory = false});

  final String? workoutId;
  final bool initialHistory;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  String? _draftKey;
  late int _trainingTab = widget.initialHistory ? 1 : 0;

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final workoutId = widget.workoutId;
    if (workoutId == null) {
      return PageShell(
        dark: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.training,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 14),
            TabSelector(
              labels: [l.today, l.history],
              selected: _trainingTab,
              dark: true,
              onSelected: (index) => setState(() => _trainingTab = index),
            ),
            const SizedBox(height: 18),
            _trainingTab == 0
                ? const _TrainingTodayView()
                : const _TrainingHistoryView(),
          ],
        ),
      );
    }

    final session = ref.watch(workoutSessionControllerProvider(workoutId));
    return PageShell(
      dark: true,
      child: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Text('$error', style: const TextStyle(color: Colors.white)),
        data: (state) {
          _syncControllers(state);
          final exercise = state.currentExercise;
          final set = state.currentSet;
          final draft = state.currentDraft;
          final exerciseNumber = state.currentExerciseIndex + 1;
          final setNumber = state.currentSetIndex + 1;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.workout.title,
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '${state.workout.category}  -  ${state.workout.focus}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              TabSelector(
                labels: [l.today, l.history, l.video, l.notes],
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
                    Positioned.fill(
                      child: Image(
                        image: AssetImage(
                          exerciseHeroImagePath(exercise.exerciseId),
                        ),
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: .22),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: Wrap(
                        spacing: 8,
                        children: [
                          StatusBadge(
                            label:
                                '${l.exercise} $exerciseNumber ${l.ofLabel} ${state.workout.exercises.length}',
                            dark: true,
                          ),
                          StatusBadge(
                            label:
                                '${l.set} $setNumber ${l.ofLabel} ${exercise.sets.length}',
                            dark: true,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 58,
                      child: Text(
                        exercise.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: state.progress,
                color: AppColors.primaryGreen,
                backgroundColor: Colors.white12,
                minHeight: 8,
                borderRadius: BorderRadius.circular(99),
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
                    label:
                        '${state.completedSets}/${state.totalSets} ${l.setsCompleted}',
                    dark: true,
                    icon: Icons.check_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: darkBoxDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.coachTarget,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${set.targetReps} ${l.reps} x ${targetWeightLabel(set)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    if (exercise.coachingNote != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        exercise.coachingNote!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _NumberField(
                            label: l.actualReps,
                            controller: _repsController,
                            onChanged: (value) => _updateReps(workoutId, value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _NumberField(
                            label: l.actualWeight,
                            controller: _weightController,
                            onChanged: (value) =>
                                _updateWeight(workoutId, value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l.rpe,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (var rpe = 1; rpe <= 10; rpe++)
                          ChoiceChip(
                            label: Text('$rpe'),
                            selected: draft.rpe == rpe,
                            onSelected: (_) => ref
                                .read(
                                  workoutSessionControllerProvider(
                                    workoutId,
                                  ).notifier,
                                )
                                .updateRpe(rpe.toDouble()),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                onChanged: ref
                    .read(workoutSessionControllerProvider(workoutId).notifier)
                    .updateWorkoutNote,
                minLines: 2,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: l.workoutNote,
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: AppColors.darkSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: l.previousSet,
                      dark: true,
                      onPressed:
                          state.currentExerciseIndex == 0 &&
                              state.currentSetIndex == 0
                          ? null
                          : () => ref
                                .read(
                                  workoutSessionControllerProvider(
                                    workoutId,
                                  ).notifier,
                                )
                                .previousSet(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: draft.completed ? l.completed : l.completeSet,
                      icon: Icons.check_rounded,
                      onPressed: () => _completeSet(context, workoutId, state),
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

  void _syncControllers(WorkoutSessionState state) {
    if (_draftKey == state.currentDraftKey) {
      return;
    }
    _draftKey = state.currentDraftKey;
    _repsController.text = state.currentDraft.repsInput;
    _weightController.text = state.currentDraft.weightInput;
    _noteController.text = state.workoutNote;
  }

  void _updateReps(String workoutId, String value) {
    ref
        .read(workoutSessionControllerProvider(workoutId).notifier)
        .updateActualRepsInput(value);
  }

  void _updateWeight(String workoutId, String value) {
    ref
        .read(workoutSessionControllerProvider(workoutId).notifier)
        .updateActualWeightInput(value);
  }

  Future<void> _completeSet(
    BuildContext context,
    String workoutId,
    WorkoutSessionState state,
  ) async {
    final l = AppLocalizations.of(context)!;
    final draft = state.currentDraft;
    if (!draft.isValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.invalidPerformanceInput)));
      return;
    }
    try {
      ref
          .read(workoutSessionControllerProvider(workoutId).notifier)
          .completeCurrentSet();
    } on StateError {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.invalidPerformanceInput)));
      return;
    }
    final updated = ref
        .read(workoutSessionControllerProvider(workoutId))
        .requireValue;
    if (state.isLastSet &&
        updated.completedSets == updated.totalSets &&
        context.mounted) {
      await _showFinishSheet(context, workoutId, updated);
    }
  }

  Future<void> _showFinishSheet(
    BuildContext context,
    String workoutId,
    WorkoutSessionState state,
  ) {
    final l = AppLocalizations.of(context)!;
    final averageRpe = _averageRpe(state);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.workoutComplete,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.completedSets} ${l.setsCompleted}${averageRpe == null ? '' : '  -  ${l.averageRpe}: ${averageRpe.toStringAsFixed(1)}'}',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: l.finishWorkout,
              icon: Icons.flag_rounded,
              onPressed: () async {
                await ref
                    .read(workoutSessionControllerProvider(workoutId).notifier)
                    .finishWorkout();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  context.go('${AppRoutes.training}?tab=history');
                }
              },
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: l.continueEditing,
              dark: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  double? _averageRpe(WorkoutSessionState state) {
    final rpes = state.drafts.values
        .where((draft) => draft.completed && draft.rpe != null)
        .map((draft) => draft.rpe!)
        .toList();
    if (rpes.isEmpty) {
      return null;
    }
    return rpes.reduce((a, b) => a + b) / rpes.length;
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    );
  }
}

class _TrainingTodayView extends ConsumerWidget {
  const _TrainingTodayView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final workout = ref.watch(workoutControllerProvider);
    return workout.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Text('$error', style: const TextStyle(color: Colors.white)),
      data: (workout) => Container(
        padding: const EdgeInsets.all(16),
        decoration: darkBoxDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workout.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              '${workout.category}  -  ${workout.focus}',
              style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            for (final exercise in workout.exercises)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Image.asset(
                          exerciseImagePath(exercise.exerciseId),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            exercisePrescriptionDetail(exercise),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: l.startWorkout,
              icon: Icons.arrow_forward_rounded,
              onPressed: () => context.go(AppRoutes.workoutPath(workout.id)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingHistoryView extends ConsumerWidget {
  const _TrainingHistoryView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final history = ref.watch(workoutHistoryProvider);
    return history.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Text('$error', style: const TextStyle(color: Colors.white)),
      data: (items) => items.isEmpty
          ? Text(
              l.noWorkoutHistory,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            )
          : Column(
              children: [
                for (final result in items.reversed)
                  _WorkoutHistoryCard(result: result),
              ],
            ),
    );
  }
}

class _WorkoutHistoryCard extends StatelessWidget {
  const _WorkoutHistoryCard({required this.result});

  final WorkoutHistoryEntry result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final completedSets = result.setResults
        .where((set) => set.completed)
        .length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: darkBoxDecoration(),
        child: Row(
          children: [
            const ProgressRing(value: 1, size: 54, dark: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.workoutTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${result.completedAt.month}/${result.completedAt.day}/${result.completedAt.year}  -  $completedSets ${l.setsCompleted}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (result.notes != null)
                    Text(
                      result.notes!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
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
