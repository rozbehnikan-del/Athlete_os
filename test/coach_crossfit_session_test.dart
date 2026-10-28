import 'dart:convert';

import 'package:athlete_os/src/core/api/api_client.dart';
import 'package:athlete_os/src/core/api/api_config.dart';
import 'package:athlete_os/src/features/coach/data/api_coach_repository.dart';
import 'package:athlete_os/src/features/coach/domain/coach_models.dart';
import 'package:athlete_os/src/features/coach/domain/crossfit_session_assignment.dart';
import 'package:athlete_os/src/features/training/domain/entities/crossfit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final session = CrossFitSessionAssignment(
    title: ' CrossFit Mixed Session ',
    date: DateTime(2026, 10, 28),
    focus: 'Strength + Conditioning',
    blocks: const [
      CrossFitBlockAssignment(
        type: TrainingBlockType.warmup,
        title: 'Warm-up',
        coachNote: '5 min easy row',
      ),
      CrossFitBlockAssignment(
        type: TrainingBlockType.strength,
        title: 'Back Squat',
      ),
      CrossFitBlockAssignment(
        type: TrainingBlockType.metcon,
        title: 'EMOM 3',
        wod: CrossFitWodAssignment(
          format: WodFormat.emom,
          scoreType: WodScoreType.intervals,
          durationSeconds: 180,
          scoreConfig: {
            'minute_targets': [
              '10 Wall Balls',
              '8 Box Jumps',
              '6 Burpees',
            ],
          },
        ),
      ),
      CrossFitBlockAssignment(
        type: TrainingBlockType.accessory,
        title: 'Cooldown',
      ),
    ],
    exercises: const [
      ExerciseAssignment(
        exerciseId: '33333333-3333-4333-8333-333333333333',
        setCount: 3,
        reps: 5,
        weight: 80,
        unit: 'kg',
      ),
    ],
  );

  test('coach session payload has ordered CrossFit blocks and exact EMOM schema', () {
    final json = session.toJson();
    expect(json['title'], 'CrossFit Mixed Session');
    expect(json['scheduled_for'], '2026-10-28');
    expect(json['exercises'][0]['sets'].length, 3);
    expect(json['blocks'].map((e) => e['order']), [1, 2, 3, 4]);
    final metcon = json['blocks'][2]['wod'] as Map<String, dynamic>;
    expect(metcon['format'], 'emom');
    expect(metcon['score_type'], 'intervals');
    expect(metcon['duration_seconds'], 180);
    expect(metcon['score_config']['minute_targets'].length, 3);
    expect(metcon.containsKey('id'), isFalse);
  });

  test('coach repository posts to the session endpoint', () async {
    final repo = ApiCoachRepository(
      ApiClient(
        config: const ApiConfig(baseUrl: 'http://test.local/'),
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(
            request.url.path,
            '/v1/coaches/me/athletes/athlete-1/sessions',
          );
          final json = jsonDecode(request.body) as Map<String, dynamic>;
          expect(json['blocks'].length, 4);
          expect(json.containsKey('coach_id'), false);
          return http.Response(jsonEncode({'data': {'id': 'session-1'}}), 201);
        }),
      ),
    );
    expect(await repo.assignSession('athlete-1', session), 'session-1');
  });

  test('WOD format defaults respect backend accepted score contracts', () {
    expect(defaultScoreType(WodFormat.forTime), WodScoreType.time);
    expect(defaultScoreType(WodFormat.amrap), WodScoreType.roundsReps);
    expect(defaultScoreType(WodFormat.emom), WodScoreType.intervals);
    expect(defaultScoreType(WodFormat.maxLoad), WodScoreType.load);
    expect(defaultScoreType(WodFormat.maxReps), WodScoreType.reps);
    expect(defaultScoreType(WodFormat.custom), WodScoreType.none);
    expect(
      const CrossFitWodAssignment(
        format: WodFormat.roundsForTime,
        scoreType: WodScoreType.time,
        rounds: 5,
      ).toJson()['format'],
      'rounds_for_time',
    );
  });
}
