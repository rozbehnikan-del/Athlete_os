import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../training/domain/entities/crossfit.dart';
import '../application/coach_providers.dart';
import '../domain/coach_models.dart';
import '../domain/crossfit_session_assignment.dart';
import 'coach_screens.dart' show coachError;

class CreateCrossFitSessionScreen extends ConsumerStatefulWidget {
  const CreateCrossFitSessionScreen({super.key, required this.athleteId});

  final String athleteId;

  @override
  ConsumerState<CreateCrossFitSessionScreen> createState() =>
      _CreateCrossFitSessionState();
}

class _BlockDraft {
  _BlockDraft(this.type)
      : title = TextEditingController(
          text: switch (type) {
            TrainingBlockType.warmup => 'Warm-up',
            TrainingBlockType.strength => 'Strength',
            TrainingBlockType.skill => 'Skill',
            TrainingBlockType.metcon => 'Metcon',
            TrainingBlockType.accessory => 'Accessory / Cooldown',
          },
        );

  final TrainingBlockType type;
  final TextEditingController title;
  final note = TextEditingController();
  final durationMinutes = TextEditingController(text: '12');
  final capMinutes = TextEditingController();
  final rounds = TextEditingController(text: '5');
  final minuteTargets = TextEditingController();
  WodFormat format = WodFormat.amrap;
  bool scored = true;

  bool get supportsWod =>
      type == TrainingBlockType.metcon || type == TrainingBlockType.skill;

  void dispose() {
    title.dispose();
    note.dispose();
    durationMinutes.dispose();
    capMinutes.dispose();
    rounds.dispose();
    minuteTargets.dispose();
  }

  CrossFitBlockAssignment build() {
    final titleValue = title.text.trim();
    if (titleValue.isEmpty || titleValue.length > 180) {
      throw const FormatException('Every block needs a title up to 180 characters.');
    }
    if (note.text.length > 4000) {
      throw const FormatException('Coaching notes must be under 4000 characters.');
    }

    CrossFitWodAssignment? wod;
    if (supportsWod && scored) {
      final minutes = int.tryParse(durationMinutes.text.trim());
      final capText = capMinutes.text.trim();
      final cap = capText.isEmpty ? null : int.tryParse(capText);
      final roundsText = rounds.text.trim();
      final roundCount = roundsText.isEmpty ? null : int.tryParse(roundsText);
      final requiresDuration =
          format == WodFormat.amrap || format == WodFormat.emom;
      if (requiresDuration && (minutes == null || minutes <= 0 || minutes > 120)) {
        throw const FormatException('AMRAP / EMOM duration must be 1–120 minutes.');
      }
      if (capText.isNotEmpty && (cap == null || cap <= 0 || cap > 240)) {
        throw const FormatException('Time cap must be 1–240 minutes.');
      }
      if (format == WodFormat.roundsForTime &&
          (roundCount == null || roundCount <= 0)) {
        throw const FormatException('Rounds for Time needs a round count.');
      }

      final config = <String, dynamic>{};
      if (format == WodFormat.emom) {
        final targets = minuteTargets.text
            .split('\n')
            .map((value) => value.trim())
            .toList();
        if (targets.length != minutes ||
            targets.any((target) => target.isEmpty || target.length > 160)) {
          throw const FormatException(
            'EMOM needs exactly one target line per minute (maximum 160 characters).',
          );
        }
        config['minute_targets'] = targets;
      }

      wod = CrossFitWodAssignment(
        format: format,
        scoreType: defaultScoreType(format),
        durationSeconds: requiresDuration ? minutes! * 60 : null,
        timeCapSeconds: cap == null ? null : cap * 60,
        rounds: format == WodFormat.roundsForTime ? roundCount : null,
        scoreConfig: config,
      );
    }

    return CrossFitBlockAssignment(
      type: type,
      title: titleValue,
      coachNote: note.text.trim().isEmpty ? null : note.text.trim(),
      wod: wod,
    );
  }
}

class _StrengthDraft {
  String? exerciseId;
  final setCount = TextEditingController(text: '3');
  final reps = TextEditingController(text: '5');
  final load = TextEditingController(text: '80');
  final note = TextEditingController();
  String unit = 'kg';

  ExerciseAssignment build() {
    final count = int.tryParse(setCount.text);
    final targetReps = int.tryParse(reps.text);
    final targetLoad = double.tryParse(load.text);
    if (exerciseId == null ||
        count == null ||
        count < 1 ||
        count > 100 ||
        targetReps == null ||
        targetReps < 0 ||
        targetLoad == null ||
        !targetLoad.isFinite ||
        targetLoad < 0 ||
        targetLoad > 999999) {
      throw const FormatException(
        'Choose an exercise with valid sets, reps and weight.',
      );
    }
    return ExerciseAssignment(
      exerciseId: exerciseId!,
      setCount: count,
      reps: targetReps,
      weight: targetLoad,
      unit: unit,
      note: note.text.trim().isEmpty ? null : note.text.trim(),
    );
  }

  void dispose() {
    setCount.dispose();
    reps.dispose();
    load.dispose();
    note.dispose();
  }
}

class _CreateCrossFitSessionState
    extends ConsumerState<CreateCrossFitSessionScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(text: 'CrossFit Session');
  final _focus = TextEditingController();
  final _coachNotes = TextEditingController();
  final _blocks = <_BlockDraft>[
    _BlockDraft(TrainingBlockType.warmup),
    _BlockDraft(TrainingBlockType.strength),
    _BlockDraft(TrainingBlockType.metcon),
    _BlockDraft(TrainingBlockType.accessory),
  ];
  final _exercises = <_StrengthDraft>[_StrengthDraft()];
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _focus.dispose();
    _coachNotes.dispose();
    for (final block in _blocks) {
      block.dispose();
    }
    for (final exercise in _exercises) {
      exercise.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final hasStrength = _blocks.any(
        (block) => block.type == TrainingBlockType.strength,
      );
      final assignment = CrossFitSessionAssignment(
        title: _title.text,
        date: _date,
        focus: _focus.text.trim().isEmpty ? null : _focus.text.trim(),
        coachNotes: _coachNotes.text.trim().isEmpty
            ? null
            : _coachNotes.text.trim(),
        blocks: _blocks.map((block) => block.build()).toList(),
        exercises: hasStrength
            ? _exercises.map((exercise) => exercise.build()).toList()
            : [],
      );
      if (assignment.blocks.length > 20) {
        throw const FormatException('Maximum 20 blocks allowed.');
      }
      await ref.read(coachRepositoryProvider).assignSession(
        widget.athleteId,
        assignment,
      );
      ref.invalidate(coachAthleteProvider(widget.athleteId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CrossFit session assigned')),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is FormatException
              ? error.message
              : coachError(error);
          _saving = false;
        });
      }
    }
  }

  void _reorder(int from, int to) {
    if (to < 0 || to >= _blocks.length) return;
    setState(() {
      final block = _blocks.removeAt(from);
      _blocks.insert(to, block);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Build CrossFit Session')),
    body: ref.watch(exerciseLibraryProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(coachError(error)),
            TextButton(
              onPressed: () => ref.invalidate(exerciseLibraryProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (library) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Program the athlete session',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _title,
                  enabled: !_saving,
                  maxLength: 200,
                  decoration: const InputDecoration(labelText: 'Session title'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Session title is required.'
                      : null,
                ),
                TextFormField(
                  controller: _focus,
                  enabled: !_saving,
                  maxLength: 200,
                  decoration: const InputDecoration(labelText: 'Focus (optional)'),
                ),
                TextFormField(
                  controller: _coachNotes,
                  enabled: !_saving,
                  maxLength: 4000,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Coach notes'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Scheduled date'),
                  subtitle: Text(_date.toIso8601String().split('T').first),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _saving ? null : () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (selected != null && mounted) {
                      setState(() => _date = selected);
                    }
                  },
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Session blocks',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    PopupMenuButton<TrainingBlockType>(
                      enabled: !_saving && _blocks.length < 20,
                      tooltip: 'Add block',
                      onSelected: (type) => setState(() {
                        _blocks.add(_BlockDraft(type));
                      }),
                      itemBuilder: (context) => [
                        for (final type in TrainingBlockType.values)
                          PopupMenuItem(
                            value: type,
                            child: Text(type.name.toUpperCase()),
                          ),
                      ],
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add),
                            SizedBox(width: 4),
                            Text('Add block'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                for (var i = 0; i < _blocks.length; i++)
                  _blockEditor(_blocks[i], i),
                if (_blocks.any((b) => b.type == TrainingBlockType.strength))
                  _strengthSection(library),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'Assigning…' : 'Assign CrossFit Session'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _blockEditor(_BlockDraft block, int index) => Card(
    key: ObjectKey(block),
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${index + 1} • ${block.type.name.toUpperCase()}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Move block up',
                onPressed: _saving || index == 0
                    ? null
                    : () => _reorder(index, index - 1),
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
              IconButton(
                tooltip: 'Move block down',
                onPressed: _saving || index == _blocks.length - 1
                    ? null
                    : () => _reorder(index, index + 1),
                icon: const Icon(Icons.arrow_downward_rounded),
              ),
              IconButton(
                tooltip: 'Remove block',
                onPressed: _saving || _blocks.length <= 1
                    ? null
                    : () {
                        setState(() => _blocks.remove(block));
                        block.dispose();
                      },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          TextFormField(
            controller: block.title,
            enabled: !_saving,
            maxLength: 180,
            decoration: const InputDecoration(labelText: 'Block title'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Block title required.'
                : null,
          ),
          TextFormField(
            controller: block.note,
            enabled: !_saving,
            maxLength: 4000,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Instructions / coaching cues',
            ),
          ),
          if (block.supportsWod) ...[
            SwitchListTile(
              value: block.scored,
              title: const Text('Scored WOD'),
              subtitle: const Text('Athlete logs a result for this block'),
              onChanged: _saving
                  ? null
                  : (enabled) => setState(() => block.scored = enabled),
            ),
            if (block.scored) ...[
              DropdownButtonFormField<WodFormat>(
                key: ValueKey('wod-format-${identityHashCode(block)}'),
                initialValue: block.format,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'WOD format'),
                items: [
                  for (final format in WodFormat.values)
                    DropdownMenuItem(
                      value: format,
                      child: Text(wodFormatLabel(format)),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            block.format = value;
                            if (value == WodFormat.emom) {
                              block.durationMinutes.text = '3';
                            }
                          });
                        }
                      },
              ),
              if (block.format == WodFormat.amrap ||
                  block.format == WodFormat.emom)
                TextFormField(
                  controller: block.durationMinutes,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                  ),
                  validator: (value) {
                    final n = int.tryParse(value ?? '');
                    return n == null || n < 1 || n > 120
                        ? 'Enter 1–120 minutes.'
                        : null;
                  },
                ),
              if (block.format == WodFormat.emom)
                TextFormField(
                  controller: block.minuteTargets,
                  enabled: !_saving,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'One target per minute (one line each)',
                    hintText: '10 Wall Balls\n8 Box Jumps\n6 Burpees',
                  ),
                ),
              if (block.format == WodFormat.roundsForTime)
                TextFormField(
                  controller: block.rounds,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rounds'),
                  validator: (value) {
                    final n = int.tryParse(value ?? '');
                    return n == null || n < 1 ? 'Enter round count.' : null;
                  },
                ),
              TextFormField(
                controller: block.capMinutes,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Time cap in minutes (optional)',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final n = int.tryParse(value);
                  return n == null || n < 1 || n > 240
                      ? 'Time cap must be 1–240 minutes.'
                      : null;
                },
              ),
            ],
          ],
        ],
      ),
    ),
  );

  Widget _strengthSection(List<LibraryExercise> library) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      Text('Strength prescriptions',
          style: Theme.of(context).textTheme.titleLarge),
      if (library.isEmpty)
        const Text('No exercises available. Add exercises to the library first.'),
      for (var i = 0; i < _exercises.length; i++)
        _strengthEditor(_exercises[i], i, library),
      OutlinedButton.icon(
        onPressed: _saving || _exercises.length >= 100
            ? null
            : () => setState(() => _exercises.add(_StrengthDraft())),
        icon: const Icon(Icons.add),
        label: const Text('Add strength exercise'),
      ),
    ],
  );

  Widget _strengthEditor(
    _StrengthDraft draft,
    int index,
    List<LibraryExercise> library,
  ) => Card(
    key: ObjectKey(draft),
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Strength exercise ${index + 1}')),
              if (_exercises.length > 1)
                IconButton(
                  tooltip: 'Remove strength exercise',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _saving ? null : () {
                    setState(() => _exercises.remove(draft));
                    draft.dispose();
                  },
                ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: draft.exerciseId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Exercise'),
            items: [
              for (final exercise in library)
                DropdownMenuItem(value: exercise.id, child: Text(exercise.name)),
            ],
            onChanged: _saving ? null : (id) => draft.exerciseId = id,
            validator: (value) => value == null ? 'Select exercise.' : null,
          ),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 115,
                child: TextFormField(
                  controller: draft.setCount,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sets'),
                ),
              ),
              SizedBox(
                width: 115,
                child: TextFormField(
                  controller: draft.reps,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Reps'),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: draft.load,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Target load'),
                ),
              ),
              SizedBox(
                width: 90,
                child: DropdownButtonFormField<String>(
                  initialValue: draft.unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: const [
                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                    DropdownMenuItem(value: 'lb', child: Text('lb')),
                  ],
                  onChanged: _saving ? null : (value) {
                    if (value != null) draft.unit = value;
                  },
                ),
              ),
            ],
          ),
          TextFormField(
            controller: draft.note,
            enabled: !_saving,
            maxLength: 4000,
            decoration: const InputDecoration(
              labelText: 'Exercise coaching note (optional)',
            ),
          ),
        ],
      ),
    ),
  );
}
