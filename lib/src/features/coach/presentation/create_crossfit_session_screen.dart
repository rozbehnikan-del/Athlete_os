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
      _CreateCrossFitSessionScreenState();
}

class _BlockInput {
  _BlockInput(this.type, String defaultTitle, {this.enabled = true})
    : title = TextEditingController(text: defaultTitle);

  final TrainingBlockType type;
  bool enabled;
  final TextEditingController title;
  final TextEditingController instructions = TextEditingController();
  final TextEditingController coachNote = TextEditingController();

  void dispose() {
    title.dispose();
    instructions.dispose();
    coachNote.dispose();
  }
}

class _StrengthInput {
  String? exerciseId;
  String unit = 'kg';
  final count = TextEditingController(text: '3');
  final reps = TextEditingController(text: '5');
  final weight = TextEditingController(text: '0');
  final note = TextEditingController();

  void dispose() {
    count.dispose();
    reps.dispose();
    weight.dispose();
    note.dispose();
  }

  ExerciseAssignment build() => ExerciseAssignment(
    exerciseId: exerciseId!,
    setCount: int.parse(count.text),
    reps: int.parse(reps.text),
    weight: double.parse(weight.text),
    unit: unit,
    note: note.text.trim().isEmpty ? null : note.text.trim(),
  );
}

class _CreateCrossFitSessionScreenState
    extends ConsumerState<CreateCrossFitSessionScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _focus = TextEditingController();
  final _coachNotes = TextEditingController();
  final _duration = TextEditingController(text: '720');
  final _cap = TextEditingController();
  final _rounds = TextEditingController(text: '5');

  final _blocks = [
    _BlockInput(TrainingBlockType.warmup, 'Warm-up'),
    _BlockInput(TrainingBlockType.strength, 'Strength'),
    _BlockInput(TrainingBlockType.skill, 'Skill', enabled: false),
    _BlockInput(TrainingBlockType.metcon, 'Metcon'),
    _BlockInput(TrainingBlockType.accessory, 'Accessory / Cooldown'),
  ];
  final _strength = <_StrengthInput>[_StrengthInput()];
  final _minuteTargets = <TextEditingController>[];
  WodFormat _format = WodFormat.amrap;
  bool _rx = true;
  bool _scaled = true;
  bool _customScaling = false;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _duration.addListener(_syncMinuteInputs);
  }

  void _syncMinuteInputs() {
    if (_format != WodFormat.emom) return;
    final seconds = int.tryParse(_duration.text) ?? 0;
    final minutes = seconds > 0 && seconds % 60 == 0 ? seconds ~/ 60 : 0;
    final count = minutes.clamp(0, 30).toInt();
    if (count == _minuteTargets.length) return;
    while (_minuteTargets.length < count) {
      _minuteTargets.add(TextEditingController());
    }
    while (_minuteTargets.length > count) {
      _minuteTargets.removeLast().dispose();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _duration.removeListener(_syncMinuteInputs);
    for (final controller in [
      _title, _focus, _coachNotes, _duration, _cap, _rounds,
    ]) {
      controller.dispose();
    }
    for (final block in _blocks) {
      block.dispose();
    }
    for (final entry in _strength) {
      entry.dispose();
    }
    for (final target in _minuteTargets) {
      target.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String? _number(String? value, {bool optional = false, int min = 1, int max = 10000}) {
    if (optional && (value == null || value.trim().isEmpty)) return null;
    final number = int.tryParse(value ?? '');
    return number == null || number < min || number > max
        ? 'Enter an integer between $min and $max.'
        : null;
  }

  String? _weight(String? value) {
    final number = double.tryParse(value ?? '');
    return number == null || !number.isFinite || number < 0 || number > 999999
        ? 'Enter a nonnegative weight.'
        : null;
  }

  bool get _requiresDuration =>
      _format == WodFormat.amrap || _format == WodFormat.emom;

  bool get _needsRounds => _format == WodFormat.roundsForTime;

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (!_rx && !_scaled && !_customScaling) {
      setState(() => _error = 'Select at least one scaling option.');
      return;
    }
    if (_format == WodFormat.emom &&
        (_minuteTargets.isEmpty ||
            _minuteTargets.any((controller) => controller.text.trim().isEmpty))) {
      setState(() => _error = 'Provide a target for every EMOM minute.');
      return;
    }

    final strengthEnabled = _blocks.any(
      (block) => block.type == TrainingBlockType.strength && block.enabled,
    );
    if (strengthEnabled && _strength.isEmpty) {
      setState(() => _error = 'Strength needs at least one exercise.');
      return;
    }

    final duration = int.tryParse(_duration.text);
    final cap = int.tryParse(_cap.text);
    final rounds = int.tryParse(_rounds.text);
    final wod = CrossFitWodAssignment(
      format: _format,
      scoreType: defaultScoreType(_format),
      durationSeconds: _requiresDuration ? duration : null,
      timeCapSeconds: cap,
      rounds: _needsRounds ? rounds : null,
      scalingOptions: [
        if (_rx) ScalingLevel.rx,
        if (_scaled) ScalingLevel.scaled,
        if (_customScaling) ScalingLevel.custom,
      ],
      scoreConfig: _format == WodFormat.emom
          ? {'minute_targets': [for (final entry in _minuteTargets) entry.text.trim()]}
          : const {},
    );
    final blocks = [
      for (final block in _blocks)
        if (block.enabled)
          CrossFitBlockAssignment(
            type: block.type,
            title: block.title.text,
            coachNote: block.coachNote.text.trim().isEmpty
                ? null
                : block.coachNote.text.trim(),
            prescription: block.instructions.text.trim().isEmpty
                ? const {}
                : {'instructions': block.instructions.text.trim()},
            wod: block.type == TrainingBlockType.metcon ? wod : null,
          ),
    ];

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(coachRepositoryProvider).assignSession(
        widget.athleteId,
        CrossFitSessionAssignment(
          title: _title.text,
          focus: _focus.text.trim().isEmpty ? null : _focus.text.trim(),
          coachNotes: _coachNotes.text.trim().isEmpty
              ? null
              : _coachNotes.text.trim(),
          date: _date,
          blocks: blocks,
          exercises: strengthEnabled
              ? [for (final entry in _strength) entry.build()]
              : const [],
        ),
      );
      ref.invalidate(coachAthleteProvider(widget.athleteId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CrossFit session assigned.')),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = coachError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('CrossFit Session Builder')),
    body: ref.watch(exerciseLibraryProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(coachError(error))),
      data: (library) => Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROGRAM THE SESSION',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Coach-defined blocks and scores. Athletes execute them in order.'),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _title,
                            decoration: const InputDecoration(labelText: 'Session title'),
                            maxLength: 200,
                            validator: _required,
                          ),
                          TextFormField(
                            controller: _focus,
                            decoration: const InputDecoration(labelText: 'Focus (optional)'),
                            maxLength: 200,
                          ),
                          TextFormField(
                            controller: _coachNotes,
                            decoration: const InputDecoration(labelText: 'Coach notes (optional)'),
                            maxLength: 4000,
                          ),
                          ListTile(
                            title: const Text('Scheduled date'),
                            subtitle: Text(_date.toIso8601String().split('T').first),
                            trailing: const Icon(Icons.calendar_today_rounded),
                            onTap: _saving ? null : () async {
                              final selected = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (selected != null && mounted) setState(() => _date = selected);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final block in _blocks)
                    _blockCard(block, library),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(_saving ? 'Assigning…' : 'Assign CrossFit Session'),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _blockCard(_BlockInput block, List<LibraryExercise> library) {
    final isMetcon = block.type == TrainingBlockType.metcon;
    final isStrength = block.type == TrainingBlockType.strength;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(block.type.name.toUpperCase()),
              subtitle: isMetcon ? const Text('Required scored WOD') : null,
              value: block.enabled,
              onChanged: isMetcon || _saving
                  ? null
                  : (enabled) => setState(() => block.enabled = enabled),
            ),
            if (block.enabled) ...[
              TextFormField(
                controller: block.title,
                maxLength: 180,
                decoration: const InputDecoration(labelText: 'Block title'),
                validator: _required,
              ),
              TextFormField(
                controller: block.instructions,
                maxLength: 4000,
                decoration: const InputDecoration(labelText: 'Instructions / movement prescription'),
              ),
              TextFormField(
                controller: block.coachNote,
                maxLength: 4000,
                decoration: const InputDecoration(labelText: 'Private coach guidance (optional)'),
              ),
              if (isStrength) _strengthEditor(library),
              if (isMetcon) _metconEditor(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _strengthEditor(List<LibraryExercise> library) => Column(
    children: [
      for (var index = 0; index < _strength.length; index++)
        Card(
          key: ObjectKey(_strength[index]),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Strength exercise ${index + 1}')),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      tooltip: 'Remove exercise',
                      onPressed: _saving ? null : () {
                        setState(() {
                          final old = _strength.removeAt(index);
                          old.dispose();
                        });
                      },
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  initialValue: _strength[index].exerciseId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Exercise'),
                  items: [
                    for (final exercise in library)
                      DropdownMenuItem(value: exercise.id, child: Text(exercise.name)),
                  ],
                  onChanged: _saving ? null : (value) => _strength[index].exerciseId = value,
                  validator: (value) => value == null ? 'Select an exercise.' : null,
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: 130,
                      child: TextFormField(
                        controller: _strength[index].count,
                        decoration: const InputDecoration(labelText: 'Sets'),
                        keyboardType: TextInputType.number,
                        validator: (value) => _number(value, max: 100),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: TextFormField(
                        controller: _strength[index].reps,
                        decoration: const InputDecoration(labelText: 'Reps'),
                        keyboardType: TextInputType.number,
                        validator: (value) => _number(value, min: 0),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: TextFormField(
                        controller: _strength[index].weight,
                        decoration: const InputDecoration(labelText: 'Weight'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: _weight,
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: DropdownButtonFormField<String>(
                        initialValue: _strength[index].unit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: const [
                          DropdownMenuItem(value: 'kg', child: Text('kg')),
                          DropdownMenuItem(value: 'lb', child: Text('lb')),
                        ],
                        onChanged: (unit) {
                          if (unit != null) _strength[index].unit = unit;
                        },
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _strength[index].note,
                  decoration: const InputDecoration(labelText: 'Coaching note'),
                ),
              ],
            ),
          ),
        ),
      TextButton.icon(
        onPressed: _saving || _strength.length >= 100
            ? null
            : () => setState(() => _strength.add(_StrengthInput())),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add strength exercise'),
      ),
    ],
  );

  Widget _metconEditor() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<WodFormat>(
        initialValue: _format,
        decoration: const InputDecoration(labelText: 'WOD format'),
        items: [
          for (final option in WodFormat.values)
            DropdownMenuItem(value: option, child: Text(wodFormatLabel(option))),
        ],
        onChanged: _saving ? null : (next) {
          if (next == null) return;
          setState(() => _format = next);
          _syncMinuteInputs();
        },
      ),
      Text('Score: ${defaultScoreType(_format).name.toUpperCase()}'),
      const SizedBox(height: 8),
      if (_requiresDuration ||
          _format == WodFormat.intervals ||
          _format == WodFormat.tabata)
        TextFormField(
          controller: _duration,
          decoration: const InputDecoration(labelText: 'Duration (seconds)'),
          keyboardType: TextInputType.number,
          validator: (value) => _number(value, optional: !_requiresDuration, max: 36000),
        ),
      if (_format == WodFormat.forTime ||
          _format == WodFormat.roundsForTime ||
          _format == WodFormat.chipper)
        TextFormField(
          controller: _cap,
          decoration: const InputDecoration(labelText: 'Time cap in seconds (optional)'),
          keyboardType: TextInputType.number,
          validator: (value) => _number(value, optional: true, max: 36000),
        ),
      if (_needsRounds)
        TextFormField(
          controller: _rounds,
          decoration: const InputDecoration(labelText: 'Number of rounds'),
          keyboardType: TextInputType.number,
          validator: (value) => _number(value, max: 1000),
        ),
      if (_format == WodFormat.emom) ...[
        const SizedBox(height: 10),
        const Text('Enter a target for every minute. Duration must be a multiple of 60 seconds (max 30 min).'),
        if (_minuteTargets.isEmpty)
          const Text('Enter a valid EMOM duration to edit minute targets.'),
        for (var index = 0; index < _minuteTargets.length; index++)
          TextFormField(
            controller: _minuteTargets[index],
            decoration: InputDecoration(labelText: 'Minute ${index + 1} target'),
            validator: _required,
          ),
      ],
      const SizedBox(height: 10),
      const Text('Scaling options'),
      Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('Rx'),
            selected: _rx,
            onSelected: (value) => setState(() => _rx = value),
          ),
          FilterChip(
            label: const Text('Scaled'),
            selected: _scaled,
            onSelected: (value) => setState(() => _scaled = value),
          ),
          FilterChip(
            label: const Text('Custom'),
            selected: _customScaling,
            onSelected: (value) => setState(() => _customScaling = value),
          ),
        ],
      ),
    ],
  );
}
