import 'dart:convert';

import 'package:athlete_os/src/core/api/api_client.dart';
import 'package:athlete_os/src/core/api/api_config.dart';
import 'package:athlete_os/src/core/api/api_providers.dart';
import 'package:athlete_os/src/core/auth/user_role.dart';
import 'package:athlete_os/src/core/errors/app_exception.dart';
import 'package:athlete_os/src/features/auth/application/auth_controller.dart';
import 'package:athlete_os/src/features/auth/data/repositories/api_auth_repository.dart';
import 'package:athlete_os/src/features/auth/domain/entities/auth_user.dart';
import 'package:athlete_os/src/app/athlete_os_app.dart';
import 'package:athlete_os/src/features/training/application/workout_providers.dart';
import 'package:athlete_os/src/features/training/data/repositories/mock_workout_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers/fake_auth_repository.dart';

void main() {
  final userJson = {
    'id': testAthlete.id,
    'email': testAthlete.email,
    'phone': null,
    'full_name': 'Ali',
    'role': 'athlete',
    'is_active': true,
  };

  ApiClient clientFor(
    MemoryTokenStorage storage,
    Future<http.Response> Function(http.Request) handler, {
    void Function()? onUnauthorized,
  }) => ApiClient(
    config: const ApiConfig(baseUrl: 'http://api.test'),
    tokenStorage: storage,
    httpClient: MockClient(handler),
    onUnauthorized: onUnauthorized,
  );

  test(
    'login parses and stores token before fetching current user with Bearer header',
    () async {
      final storage = MemoryTokenStorage();
      final paths = <String>[];
      final client = clientFor(storage, (request) async {
        paths.add(request.url.path);
        if (request.url.path == '/v1/auth/login') {
          expect(request.headers.containsKey('Authorization'), isFalse);
          expect(jsonDecode(request.body), {
            'email': 'ali@athleteos.local',
            'password': 'test-password',
          });
          return http.Response(
            jsonEncode({
              'data': {
                'access_token': 'token',
                'token_type': 'bearer',
                'expires_in': 3600,
              },
            }),
            200,
          );
        }
        expect(storage.token, 'token');
        expect(request.headers['Authorization'], 'Bearer token');
        return http.Response(jsonEncode({'data': userJson}), 200);
      });
      addTearDown(client.close);
      final repository = ApiAuthRepository(client, storage);
      final session = await repository.login(
        email: 'ali@athleteos.local',
        password: 'test-password',
      );
      expect(paths, ['/v1/auth/login', '/v1/auth/me']);
      expect(session.accessToken, 'token');
      expect(session.tokenType, 'bearer');
      expect(session.expiresIn, 3600);
      expect(session.user.id, testAthlete.id);
      expect(session.user.phone, isNull);
      expect(session.user.email, testAthlete.email);
      expect(session.user.fullName, 'Ali');
      expect(session.user.role, UserRole.athlete);
      expect(session.user.isActive, isTrue);
      await repository.logout();
      expect(storage.token, isNull);
    },
  );

  test(
    'malformed login token is rejected without storing credentials',
    () async {
      final storage = MemoryTokenStorage();
      final client = clientFor(
        storage,
        (_) async => http.Response('{"data":{"access_token":null}}', 200),
      );
      addTearDown(client.close);
      await expectLater(
        ApiAuthRepository(client, storage).login(email: 'a', password: 'b'),
        throwsA(isA<RepositoryException>()),
      );
      expect(storage.token, isNull);
    },
  );

  test('failed me after login removes provisional token', () async {
    final storage = MemoryTokenStorage();
    final client = clientFor(
      storage,
      (request) async => request.url.path.endsWith('login')
          ? http.Response(
              '{"data":{"access_token":"token","token_type":"bearer","expires_in":3600}}',
              200,
            )
          : http.Response('{"data":{}}', 200),
    );
    addTearDown(client.close);
    await expectLater(
      ApiAuthRepository(client, storage).login(email: 'a', password: 'b'),
      throwsA(isA<RepositoryException>()),
    );
    expect(storage.token, isNull);
  });

  for (final token in <String?>[null, 'token']) {
    test('Training GET and POST headers with token=$token', () async {
      final client = clientFor(MemoryTokenStorage(token), (request) async {
        expect(
          request.headers['Authorization'],
          token == null ? null : 'Bearer token',
        );
        expect(request.headers['Content-Type'], 'application/json');
        expect(request.url.queryParameters.containsKey('athlete_id'), isFalse);
        return http.Response('{"data":null}', 200);
      });
      addTearDown(client.close);
      await client.get('/v1/athletes/me/workouts/today');
      await client.post('/v1/workouts/id/results', body: {'sets': []});
    });
  }

  test(
    'protected 401 clears token and notifies session expiry, even with non-JSON body',
    () async {
      final storage = MemoryTokenStorage('expired');
      var notified = false;
      final client = clientFor(
        storage,
        (_) async => http.Response('Unauthorized', 401),
        onUnauthorized: () => notified = true,
      );
      addTearDown(client.close);
      await expectLater(
        client.get('/v1/auth/me'),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(storage.token, isNull);
      expect(notified, isTrue);
    },
  );

  test('403 preserves session', () async {
    final storage = MemoryTokenStorage('token');
    final client = clientFor(
      storage,
      (_) async => http.Response('{}', 403),
      onUnauthorized: () => fail('403 must not expire session'),
    );
    addTearDown(client.close);
    await expectLater(
      client.get('/v1/athletes/me/workouts/today'),
      throwsA(isA<RepositoryException>()),
    );
    expect(storage.token, 'token');
  });

  ProviderContainer containerFor(FakeAuthRepository repository) {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'bootstrap without token is unauthenticated and does not call me',
    () async {
      final repository = FakeAuthRepository(token: null);
      final container = containerFor(repository);
      expect(await container.read(authControllerProvider.future), isNull);
      expect(repository.currentUserCalls, 0);
    },
  );

  test('valid bootstrap authenticates, logout clears session', () async {
    final repository = FakeAuthRepository();
    final container = containerFor(repository);
    expect(await container.read(authControllerProvider.future), testAthlete);
    await container.read(authControllerProvider.notifier).logout();
    expect(repository.token, isNull);
    expect(container.read(authControllerProvider).requireValue, isNull);
  });

  test('invalid bootstrap clears token', () async {
    final repository = FakeAuthRepository(
      failure: const SessionExpiredException(),
    );
    final container = containerFor(repository);
    expect(await container.read(authControllerProvider.future), isNull);
    expect(repository.token, isNull);
  });

  test('invalid login remains unauthenticated with friendly error', () async {
    final repository = FakeAuthRepository(
      token: null,
      failure: const RepositoryException('Email or password is incorrect.'),
    );
    final container = containerFor(repository);
    await container.read(authControllerProvider.future);
    await container
        .read(authControllerProvider.notifier)
        .login(email: 'a', password: 'b');
    expect(container.read(authControllerProvider).hasError, isTrue);
    expect(container.read(authControllerProvider).asData?.value, isNull);
    expect(repository.token, isNull);
  });

  test('central session expiry clears authenticated controller', () async {
    final container = containerFor(FakeAuthRepository());
    await container.read(authControllerProvider.future);
    container.read(sessionExpiryProvider.notifier).notify();
    expect(container.read(authControllerProvider).requireValue, isNull);
  });

  for (final role in [UserRole.athlete, UserRole.coach]) {
    testWidgets('$role route guard', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(
                user: AuthUser(
                  id: 'user',
                  fullName: 'User',
                  role: role,
                  isActive: true,
                ),
              ),
            ),
            workoutRepositoryProvider.overrideWith(
              (ref) => MockWorkoutRepository(),
            ),
          ],
          child: const AthleteOSApp(),
        ),
      );
      await tester.pumpAndSettle();
      if (role == UserRole.athlete) {
        expect(find.text('Get Started'), findsOneWidget);
        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();
        expect(find.text("Today's Workout"), findsOneWidget);
        expect(find.text('User'), findsOneWidget);
      } else {
        expect(
          find.text('coach experience is not available yet.'),
          findsOneWidget,
        );
        expect(find.text("Today's Workout"), findsNothing);
      }
    });
  }

  testWidgets(
    'unauthenticated login validates empty fields and obscures password',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(token: null),
            ),
          ],
          child: const AthleteOSApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Let's get started"), findsOneWidget);
      await tester.tap(find.text('Continue with Email'));
      await tester.pumpAndSettle();
      expect(find.text('Sign In'), findsOneWidget);
      expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .last
            .obscureText,
        isTrue,
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your email.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
    },
  );
}
