import 'dart:async';

import 'package:athlete_os/src/app/athlete_os_app.dart';
import 'package:athlete_os/src/core/errors/app_exception.dart';
import 'package:athlete_os/src/features/auth/application/auth_controller.dart';
import 'package:athlete_os/src/features/auth/domain/entities/auth_session.dart';
import 'package:athlete_os/src/features/training/application/workout_providers.dart';
import 'package:athlete_os/src/features/training/data/repositories/mock_workout_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_auth_repository.dart';

class PendingLoginRepository extends FakeAuthRepository {
  PendingLoginRepository() : super(token: null);
  final result = Completer<AuthSession>();
  String? submittedEmail;
  String? submittedPassword;

  @override
  Future<AuthSession> login({required String email, required String password}) {
    submittedEmail = email;
    submittedPassword = password;
    return result.future;
  }
}

void main() {
  Future<void> openAuth(
    WidgetTester tester,
    FakeAuthRepository repository,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          workoutRepositoryProvider.overrideWith(
            (ref) => MockWorkoutRepository(),
          ),
        ],
        child: const AthleteOSApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openEmail(WidgetTester tester) async {
    await tester.tap(find.text('Continue with Email'));
    await tester.pumpAndSettle();
  }

  testWidgets('welcome opens email form and back returns to welcome', (
    tester,
  ) async {
    await openAuth(tester, FakeAuthRepository(token: null));
    expect(find.text("Let's get started"), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    await openEmail(tester);
    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(
      tester
          .widgetList<EditableText>(find.byType(EditableText))
          .last
          .obscureText,
      isFalse,
    );
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(
      tester
          .widgetList<EditableText>(find.byType(EditableText))
          .last
          .obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text("Let's get started"), findsOneWidget);
  });

  testWidgets(
    'sign-in submits through controller, disables inputs, redirects and logs out',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = PendingLoginRepository();
      await openAuth(tester, repository);
      await openEmail(tester);
      await tester.enterText(
        find.byType(TextFormField).first,
        ' ali@athleteos.local ',
      );
      await tester.enterText(find.byType(TextFormField).last, 'test-password');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(repository.submittedEmail, 'ali@athleteos.local');
      expect(repository.submittedPassword, 'test-password');
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        tester
            .widgetList<TextFormField>(find.byType(TextFormField))
            .every((field) => field.enabled == false),
        isTrue,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .color,
        Theme.of(
          tester.element(find.byType(CircularProgressIndicator)),
        ).colorScheme.primary,
      );
      expect(find.text('Sign in to your account'), findsOneWidget);
      repository.result.complete(
        const AuthSession(
          accessToken: 'test-token',
          tokenType: 'bearer',
          expiresIn: 3600,
          user: testAthlete,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Get Started'), findsOneWidget);
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      expect(find.text("Today's Workout"), findsOneWidget);
      await tester.tap(find.byIcon(Icons.grid_view_rounded).hitTestable());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sign Out'));
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();
      expect(find.text("Let's get started"), findsOneWidget);
      expect(find.text("Today's Workout"), findsNothing);
    },
  );

  for (final message in [
    'Email or password is incorrect.',
    'Internal server detail',
  ]) {
    testWidgets('safe inline login error: $message', (tester) async {
      await openAuth(
        tester,
        FakeAuthRepository(token: null, failure: RepositoryException(message)),
      );
      await openEmail(tester);
      await tester.enterText(
        find.byType(TextFormField).first,
        'ali@example.test',
      );
      await tester.enterText(find.byType(TextFormField).last, 'test-password');
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          message == 'Email or password is incorrect.'
              ? message
              : 'Unable to sign in. Please try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Sign in to your account'), findsOneWidget);
      expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .last
            .controller
            .text,
        isEmpty,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });
  }

  for (final size in [const Size(320, 568), const Size(1440, 900)]) {
    testWidgets('auth layout fits $size and a raised keyboard', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await openAuth(tester, FakeAuthRepository(token: null));
      final welcomeButton = tester.getRect(find.byType(FilledButton));
      expect(welcomeButton.width, lessThanOrEqualTo(400));
      expect(welcomeButton.left, greaterThanOrEqualTo(24));
      await openEmail(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.byType(FilledButton).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
