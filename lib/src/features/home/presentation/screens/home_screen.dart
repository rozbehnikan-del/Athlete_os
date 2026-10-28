import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/theme/figma_v1_tokens.dart';
import '../../../../core/widgets/page_shell.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../training/application/controllers/workout_controller.dart';
import '../../../training/domain/entities/crossfit.dart';
import '../../../training/domain/entities/workout.dart';
import '../../../training/presentation/training_formatters.dart';

/// Figma: 02 — Athlete Mobile / Home (node 2:6).
/// Visual values come from the V1 foundations. Session data stays API-driven.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final user = ref.watch(authControllerProvider).asData?.value;
    final name = user?.fullName.trim() ?? '';
    final firstName = name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
    final greeting = locale.languageCode == 'en'
        ? 'Good morning'
        : l.goodMorning;
    final heading = firstName.isEmpty ? greeting : '$greeting, $firstName';
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return PageShell(
      maxWidth: 560,
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            key: const Key('home-greeting'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            locale.languageCode == 'en'
                ? _englishDate(now)
                : MaterialLocalizations.of(context).formatMediumDate(now),
            style: TextStyle(
              fontSize: 13,
              height: 1.3,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          _TodayTrainingCard(
            sectionTitle: locale.languageCode == 'en'
                ? "TODAY'S TRAINING"
                : l.todaysWorkout,
            startLabel: l.startWorkout,
          ),
          const SizedBox(height: 18),
          const _LatestSignalCard(),
        ],
      ),
    );
  }
}

String _englishDate(DateTime date) {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday'];
  const months = ['January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'];
  return '${days[date.weekday - 1]} · ${months[date.month - 1]} ${date.day}';
}

class _TodayTrainingCard extends ConsumerWidget {
  const _TodayTrainingCard({
    required this.sectionTitle,
    required this.startLabel,
  });

  final String sectionTitle;
  final String startLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(workoutControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    return _V1Card(
      padding: const EdgeInsets.all(18),
      child: workout.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionEyebrow(sectionTitle),
            const SizedBox(height: 8),
            Text('Could not load today’s training.',
                style: TextStyle(color: scheme.error)),
            TextButton(
              onPressed: () => ref.invalidate(workoutControllerProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
        data: (session) {
          if (session == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionEyebrow(sectionTitle),
                const SizedBox(height: 6),
                Text('No training assigned today',
                    style: TextStyle(fontSize: 20,
                        fontWeight: FontWeight.w700, color: scheme.onSurface)),
                const SizedBox(height: 10),
                Text('Your next coach-programmed session will appear here.',
                    style: TextStyle(fontSize: 13,
                        color: scheme.onSurfaceVariant)),
              ],
            );
          }
          final overview = _trainingOverview(session);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SectionEyebrow(sectionTitle),
                      const SizedBox(height: 4),
                      Text(session.title,
                        key: const Key('home-training-title'),
                        style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w700, height: 1.2,
                          color: scheme.onSurface)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: FigmaV1Tokens.successSurface,
                      borderRadius: BorderRadius.circular(99)),
                    child: const Text('READY', style: TextStyle(
                      color: FigmaV1Tokens.success,
                      fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < overview.length; i++) ...[
                Text(overview[i],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: i == 0 ? 14 : 13,
                    fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
                    color: i == 0 ? scheme.onSurface : scheme.onSurfaceVariant,
                    height: 1.3)),
                if (i < overview.length - 1) const SizedBox(height: 8),
              ],
              const SizedBox(height: 10),
              SizedBox(
                key: const Key('home-start-workout'),
                width: double.infinity,
                height: FigmaV1Tokens.primaryButtonHeight,
                child: FilledButton(
                  onPressed: () => context.go(AppRoutes.workoutPath(session.id)),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        FigmaV1Tokens.primaryButtonRadius)),
                  ),
                  child: Text(startLabel, style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

List<String> _trainingOverview(Workout workout) {
  final lines = <String>[];
  if (workout.exercises.isNotEmpty) {
    final first = workout.exercises.first;
    final detail = exercisePrescriptionDetail(first);
    lines.add('A. ${first.name}${detail.isEmpty ? '' : ' · $detail'}');
  }

  for (final block in workout.session?.blocks ?? const <TrainingBlock>[]) {
    final wod = block.wod;
    if (wod == null) continue;
    final duration = wod.durationSeconds == null
        ? ''
        : '${wod.durationSeconds! ~/ 60} min ';
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
    lines.add('${String.fromCharCode(65 + lines.length)}. $duration$format · ${block.title}');
    break;
  }

  for (final exercise in workout.exercises.skip(1)) {
    if (lines.length >= 2) break;
    final detail = exercisePrescriptionDetail(exercise);
    lines.add('${String.fromCharCode(65 + lines.length)}. ${exercise.name}${detail.isEmpty ? '' : ' · $detail'}');
  }
  if (lines.isEmpty && workout.focus.trim().isNotEmpty) {
    lines.add(workout.focus.trim());
  }
  return lines.take(2).toList();
}

class _LatestSignalCard extends StatelessWidget {
  const _LatestSignalCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _V1Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionEyebrow('Latest signal', fontSize: 12),
          const SizedBox(height: 10),
          Text('Your performance signals will appear here',
            style: TextStyle(color: scheme.onSurface,
                fontSize: 16, fontWeight: FontWeight.w700, height: 1.25)),
          const SizedBox(height: 10),
          Text('Training trends need verified, comparable results.',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow(this.label, {this.fontSize = 11});

  final String label;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Text(label,
    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: fontSize, fontWeight: FontWeight.w700));
}

class _V1Card extends StatelessWidget {
  const _V1Card({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(FigmaV1Tokens.cardRadius),
      ),
      child: child,
    );
  }
}
