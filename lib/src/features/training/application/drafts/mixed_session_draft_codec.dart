import 'dart:convert';

import '../controllers/crossfit_session_controller.dart';
import '../controllers/workout_session_controller.dart';
import '../../domain/entities/crossfit.dart';

class MixedSessionDraftRestored {
  const MixedSessionDraftRestored({
    required this.sets,
    required this.wods,
    required this.blockIndex,
    required this.completedBlockIds,
  });

  final Map<String, SetResultDraft> sets;
  final Map<String, WodResultDraft> wods;
  final int blockIndex;
  final Set<String> completedBlockIds;
}

/// Stores only mutable athlete entries; IDs and prescriptions come from the
/// current server response and are never trusted from the local snapshot.
class MixedSessionDraftCodec {
  static const version = 1;

  static String encode({
    required String workoutId,
    required Map<String, SetResultDraft> sets,
    required Map<String, WodResultDraft> wods,
    required int blockIndex,
    required Set<String> completedBlockIds,
  }) => jsonEncode({
    'version': version,
    'workout_id': workoutId,
    'block_index': blockIndex,
    'completed_blocks': completedBlockIds.toList(),
    'sets': {
      for (final entry in sets.entries)
        entry.key: {
          'reps': entry.value.repsInput,
          'weight': entry.value.weightInput,
          'completed': entry.value.completed,
          'rpe': entry.value.rpe,
          'notes': entry.value.notes,
        },
    },
    'wods': {
      for (final entry in wods.entries)
        entry.key: {
          'scaling': entry.value.scaling.name,
          'primary': entry.value.primaryInput,
          'secondary': entry.value.secondaryInput,
          'unit': entry.value.unit,
          'dnf': entry.value.dnf,
          'rpe': entry.value.rpe,
          'notes': entry.value.notes,
          'attempts': [
            for (final attempt in entry.value.loadAttempts)
              {
                'id': attempt.id,
                'load': attempt.loadInput,
                'successful': attempt.successful,
              },
          ],
        },
    },
  });

  static MixedSessionDraftRestored? restore(
    String? source, {
    required String workoutId,
    required Map<String, SetResultDraft> sets,
    required Map<String, WodResultDraft> wods,
    required List<String> blockIds,
  }) {
    if (source == null) return null;
    try {
      final data = jsonDecode(source);
      if (data is! Map<String, dynamic> ||
          data['version'] != version ||
          data['workout_id'] != workoutId) {
        return null;
      }

      final storedSets = data['sets'];
      final restoredSets = Map<String, SetResultDraft>.of(sets);
      for (final entry in sets.entries) {
        final item = storedSets is Map ? storedSets[entry.key] : null;
        if (item is! Map) continue;
        restoredSets[entry.key] = entry.value.copyWith(
          repsInput: item['reps'] is String ? item['reps'] as String : null,
          weightInput: item['weight'] is String ? item['weight'] as String : null,
          completed: item['completed'] is bool ? item['completed'] as bool : null,
          rpe: item['rpe'] is num ? (item['rpe'] as num).toDouble() : null,
          notes: item['notes'] is String ? item['notes'] as String : null,
        );
      }

      final storedWods = data['wods'];
      final restoredWods = Map<String, WodResultDraft>.of(wods);
      for (final entry in wods.entries) {
        final item = storedWods is Map ? storedWods[entry.key] : null;
        if (item is! Map) continue;
        ScalingLevel scaling = entry.value.scaling;
        for (final option in ScalingLevel.values) {
          if (option.name == item['scaling']) scaling = option;
        }

        final rawAttempts = item['attempts'];
        final attempts = <LoadAttemptDraft>[];
        if (rawAttempts is List) {
          for (final attempt in rawAttempts.take(30)) {
            if (attempt is Map &&
                attempt['id'] is String &&
                attempt['load'] is String &&
                attempt['successful'] is bool) {
              attempts.add(
                LoadAttemptDraft(
                  id: attempt['id'] as String,
                  loadInput: attempt['load'] as String,
                  successful: attempt['successful'] as bool,
                ),
              );
            }
          }
        }

        restoredWods[entry.key] = entry.value.copyWith(
          scaling: scaling,
          primaryInput: item['primary'] is String ? item['primary'] as String : null,
          secondaryInput: item['secondary'] is String ? item['secondary'] as String : null,
          loadAttempts: attempts,
          unit: item['unit'] is String ? item['unit'] as String : null,
          dnf: item['dnf'] is bool ? item['dnf'] as bool : null,
          rpe: item['rpe'] is num ? (item['rpe'] as num).toDouble() : null,
          notes: item['notes'] is String ? item['notes'] as String : null,
        );
      }

      final requestedIndex = data['block_index'];
      final safeIndex = requestedIndex is int && blockIds.isNotEmpty
          ? requestedIndex.clamp(0, blockIds.length - 1).toInt()
          : 0;
      final rawCompleted = data['completed_blocks'];
      final completed = rawCompleted is List
          ? rawCompleted.whereType<String>().where(blockIds.contains).toSet()
          : <String>{};

      return MixedSessionDraftRestored(
        sets: Map.unmodifiable(restoredSets),
        wods: Map.unmodifiable(restoredWods),
        blockIndex: safeIndex,
        completedBlockIds: Set.unmodifiable(completed),
      );
    } catch (_) {
      // Invalid, outdated or truncated local drafts never block loading.
      return null;
    }
  }
}
