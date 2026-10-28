import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/crossfit.dart';
import '../controllers/crossfit_session_controller.dart';
import '../controllers/workout_session_controller.dart';

final mixedSessionDraftStoreProvider = Provider<MixedSessionDraftStore>(
  (ref) => MixedSessionDraftStore(),
);

/// Workout-scoped local cache. Saving a draft never calls a workout API.
class MixedSessionDraftStore {
  Future<void> _pending = Future<void>.value();

  String _key(String workoutId) => 'athleteos.mixed_session.v1.$workoutId';

  Future<Map<String, dynamic>?> load(String workoutId) async {
    await _pending;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key(workoutId));
    if (stored == null) return null;
    try {
      final decoded = jsonDecode(stored);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> save(String workoutId, Map<String, dynamic> draft) {
    final encoded = jsonEncode(draft);
    // Serialize writes so older keystrokes cannot overwrite newer input.
    _pending = _pending.catchError((Object _) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(workoutId), encoded);
    });
    return _pending;
  }

  Future<void> clear(String workoutId) {
    _pending = _pending.catchError((Object _) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(workoutId));
    });
    return _pending;
  }
}

/// Only locally entered fields are persisted. The workout prescription and
/// identifiers come from the server on every restore.
class MixedSessionDraftSnapshot {
  const MixedSessionDraftSnapshot({
    required this.currentBlockIndex,
    required this.completedBlockIds,
    required this.setDrafts,
    required this.wodDrafts,
  });

  final int currentBlockIndex;
  final Set<String> completedBlockIds;
  final Map<String, SetResultDraft> setDrafts;
  final Map<String, WodResultDraft> wodDrafts;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'currentBlockIndex': currentBlockIndex,
    'completedBlockIds': completedBlockIds.toList(),
    'sets': {
      for (final entry in setDrafts.entries)
        entry.key: {
          'setId': entry.value.setId,
          'reps': entry.value.repsInput,
          'weight': entry.value.weightInput,
          'completed': entry.value.completed,
          'rpe': entry.value.rpe,
          'notes': entry.value.notes,
        },
    },
    'wods': {
      for (final entry in wodDrafts.entries)
        entry.key: {
          'scaling': entry.value.scaling.name,
          'primary': entry.value.primaryInput,
          'secondary': entry.value.secondaryInput,
          'unit': entry.value.unit,
          'dnf': entry.value.dnf,
          'rpe': entry.value.rpe,
          'notes': entry.value.notes,
          'loadAttempts': [
            for (final attempt in entry.value.loadAttempts)
              {
                'id': attempt.id,
                'load': attempt.loadInput,
                'successful': attempt.successful,
              },
          ],
        },
    },
  };

  static MixedSessionDraftSnapshot restore(
    Map<String, dynamic>? json, {
    required Map<String, SetResultDraft> defaultSets,
    required Map<String, WodResultDraft> defaultWods,
    required List<String> blockIds,
  }) {
    if (json == null || json['version'] != 1) {
      return MixedSessionDraftSnapshot(
        currentBlockIndex: 0,
        completedBlockIds: {},
        setDrafts: defaultSets,
        wodDrafts: defaultWods,
      );
    }

    final storedSets = json['sets'];
    final restoredSets = <String, SetResultDraft>{};
    for (final entry in defaultSets.entries) {
      final original = entry.value;
      final saved = storedSets is Map ? storedSets[entry.key] : null;
      if (saved is! Map || saved['setId'] != original.setId) {
        restoredSets[entry.key] = original;
        continue;
      }
      restoredSets[entry.key] = original.copyWith(
        repsInput: _text(saved['reps'], original.repsInput),
        weightInput: _text(saved['weight'], original.weightInput),
        completed: saved['completed'] is bool
            ? saved['completed'] as bool
            : original.completed,
        rpe: _rpe(saved['rpe']),
        notes: saved['notes'] is String
            ? saved['notes'] as String
            : original.notes,
      );
    }

    final storedWods = json['wods'];
    final restoredWods = <String, WodResultDraft>{};
    for (final entry in defaultWods.entries) {
      final original = entry.value;
      final saved = storedWods is Map ? storedWods[entry.key] : null;
      if (saved is! Map) {
        restoredWods[entry.key] = original;
        continue;
      }
      final scalingName = saved['scaling'];
      final scaling = ScalingLevel.values.where(
        (level) => level.name == scalingName,
      ).firstOrNull;
      final rawAttempts = saved['loadAttempts'];
      final attempts = <LoadAttemptDraft>[];
      if (rawAttempts is List && rawAttempts.length <= 30) {
        for (final raw in rawAttempts) {
          if (raw is Map &&
              raw['id'] is String &&
              raw['load'] is String &&
              raw['successful'] is bool) {
            attempts.add(
              LoadAttemptDraft(
                id: raw['id'] as String,
                loadInput: raw['load'] as String,
                successful: raw['successful'] as bool,
              ),
            );
          }
        }
      }
      restoredWods[entry.key] = original.copyWith(
        scaling: scaling ?? original.scaling,
        primaryInput: _text(saved['primary'], original.primaryInput),
        secondaryInput: _text(saved['secondary'], original.secondaryInput),
        unit: _text(saved['unit'], original.unit),
        dnf: saved['dnf'] is bool ? saved['dnf'] as bool : original.dnf,
        rpe: _rpe(saved['rpe']),
        notes: _text(saved['notes'], original.notes),
        loadAttempts: List.unmodifiable(attempts),
      );
    }

    final rawIndex = json['currentBlockIndex'];
    final safeIndex = rawIndex is int && blockIds.isNotEmpty
        ? rawIndex.clamp(0, blockIds.length - 1).toInt()
        : 0;
    final rawCompleted = json['completedBlockIds'];
    final validBlocks = blockIds.toSet();
    final completed = rawCompleted is List
        ? rawCompleted.whereType<String>().where(validBlocks.contains).toSet()
        : <String>{};

    return MixedSessionDraftSnapshot(
      currentBlockIndex: safeIndex,
      completedBlockIds: Set.unmodifiable(completed),
      setDrafts: Map.unmodifiable(restoredSets),
      wodDrafts: Map.unmodifiable(restoredWods),
    );
  }

  static String _text(Object? value, String fallback) =>
      value is String ? value : fallback;

  static double? _rpe(Object? value) {
    if (value is! num) return null;
    final result = value.toDouble();
    return result.isFinite && result >= 1 && result <= 10 ? result : null;
  }
}
