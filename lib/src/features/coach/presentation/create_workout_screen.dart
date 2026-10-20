import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/coach_providers.dart';
import '../domain/coach_models.dart';
import 'coach_screens.dart' show coachError;

class CreateWorkoutScreen extends ConsumerStatefulWidget {
  const CreateWorkoutScreen({super.key, required this.athleteId});
  final String athleteId;
  @override
  ConsumerState<CreateWorkoutScreen> createState() => _CreateWorkoutState();
}

class _ExerciseDraft {
  String? exerciseId;
  String? unit;
  final count = TextEditingController(text: '3');
  final reps = TextEditingController();
  final weight = TextEditingController();
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
    unit: unit!,
    note: note.text.trim().isEmpty ? null : note.text.trim(),
  );
}

class _CreateWorkoutState extends ConsumerState<CreateWorkoutScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _focus = TextEditingController();
  final _exercises = [_ExerciseDraft()];
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _focus.dispose();
    for (final e in _exercises) {
      e.dispose();
    }
    super.dispose();
  }

  String? _number(
    String? value, {
    bool integer = false,
    int min = 0,
    int? max,
  }) {
    final n = integer
        ? int.tryParse(value ?? '')
        : double.tryParse(value ?? '');
    return n == null || !n.isFinite || n < min || (max != null && n > max)
        ? 'Enter ${integer ? 'a whole number' : 'a number'} from $min${max == null ? '' : ' to $max'}.'
        : null;
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(coachRepositoryProvider)
          .assign(
            widget.athleteId,
            WorkoutAssignment(
              title: _title.text,
              category: _category.text.trim().isEmpty
                  ? null
                  : _category.text.trim(),
              focus: _focus.text.trim().isEmpty ? null : _focus.text.trim(),
              date: _date,
              exercises: _exercises.map((e) => e.build()).toList(),
            ),
          );
      ref.invalidate(coachAthleteProvider(widget.athleteId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Workout assigned')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = coachError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Workout')),
    body: ref
        .watch(exerciseLibraryProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(coachError(e)),
                TextButton(
                  onPressed: () => ref.invalidate(exerciseLibraryProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (library) => library.isEmpty
              ? const Center(child: Text('No exercises available.'))
              : Form(
                  key: _form,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _title,
                          enabled: !_saving,
                          maxLength: 200,
                          decoration: const InputDecoration(labelText: 'Title'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter a title.'
                              : null,
                        ),
                        TextFormField(
                          controller: _category,
                          enabled: !_saving,
                          maxLength: 100,
                          decoration: const InputDecoration(
                            labelText: 'Category (optional)',
                          ),
                        ),
                        TextFormField(
                          controller: _focus,
                          enabled: !_saving,
                          maxLength: 200,
                          decoration: const InputDecoration(
                            labelText: 'Focus (optional)',
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Scheduled date'),
                          subtitle: Text(
                            _date.toIso8601String().split('T').first,
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: _saving
                              ? null
                              : () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _date,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (date != null && mounted) {
                                    setState(() => _date = date);
                                  }
                                },
                        ),
                        for (var i = 0; i < _exercises.length; i++)
                          _exerciseCard(_exercises[i], i, library),
                        OutlinedButton.icon(
                          onPressed: _saving || _exercises.length >= 100
                              ? null
                              : () => setState(
                                  () => _exercises.add(_ExerciseDraft()),
                                ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add exercise'),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _saving ? null : _save,
                          child: Text(
                            _saving ? 'Assigning…' : 'Assign Workout',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
  );

  Widget _exerciseCard(
    _ExerciseDraft e,
    int index,
    List<LibraryExercise> library,
  ) => Card(
    key: ObjectKey(e),
    margin: const EdgeInsets.symmetric(vertical: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Exercise ${index + 1}')),
              if (_exercises.length > 1)
                IconButton(
                  tooltip: 'Remove exercise',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _saving
                      ? null
                      : () {
                          setState(() => _exercises.remove(e));
                          e.dispose();
                        },
                ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: e.exerciseId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Exercise'),
            items: [
              for (final exercise in library)
                DropdownMenuItem(
                  value: exercise.id,
                  child: Text(exercise.name),
                ),
            ],
            onChanged: _saving ? null : (v) => e.exerciseId = v,
            validator: (v) => v == null ? 'Select an exercise.' : null,
          ),
          TextFormField(
            controller: e.count,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Set count'),
            validator: (v) => _number(v, integer: true, min: 1, max: 100),
          ),
          TextFormField(
            controller: e.reps,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Target reps'),
            validator: (v) => _number(v, integer: true),
          ),
          TextFormField(
            controller: e.weight,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Target weight'),
            validator: (v) => _number(v, max: 999999),
          ),
          DropdownButtonFormField<String>(
            initialValue: e.unit,
            decoration: const InputDecoration(labelText: 'Weight unit'),
            items: const [
              DropdownMenuItem(value: 'kg', child: Text('kg')),
              DropdownMenuItem(value: 'lb', child: Text('lb')),
            ],
            onChanged: _saving ? null : (v) => e.unit = v,
            validator: (v) => v == null ? 'Select a weight unit.' : null,
          ),
          TextFormField(
            controller: e.note,
            enabled: !_saving,
            maxLength: 4000,
            decoration: const InputDecoration(
              labelText: 'Coaching note (optional)',
            ),
          ),
        ],
      ),
    ),
  );
}
