import '../../features/coach/presentation/coach_screens.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/user_role.dart';
import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/auth_welcome_screen.dart';

import '../../features/care_team/presentation/screens/care_team_screen.dart';
import '../../features/competition/presentation/screens/competition_screen.dart';
import '../../features/health/presentation/screens/health_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/more/presentation/screens/more_screen.dart';
import '../../features/nutrition/presentation/screens/nutrition_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/shell/athlete_app_shell.dart';
import '../../features/training/presentation/screens/workout_screen.dart';
import 'routes.dart';

GoRouter createAppRouter({
  required Locale locale,
  required ValueChanged<Locale> onLocaleChanged,
  required AsyncValue<AuthUser?> Function() authState,
  required Listenable authRefresh,
}) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final auth = authState();
      final path = state.uri.path;
      final isLogin = path == '/login' || path == '/login/email';
      if (auth.isLoading) {
        return isLogin
            ? null
            : path == '/auth-loading'
            ? null
            : '/auth-loading';
      }
      final user = auth.asData?.value;
      if (auth.hasError && path == '/auth-loading') return null;
      if (user == null) return isLogin ? null : '/login';
      if (!user.isActive ||
          (user.role != UserRole.athlete && user.role != UserRole.coach)) {
        return path == '/unsupported-role' ? null : '/unsupported-role';
      }
      if (user.role == UserRole.coach) {
        return path == '/coach' || path.startsWith('/coach/') ? null : '/coach';
      }
      if (path == '/coach' || path.startsWith('/coach/')) return AppRoutes.home;
      if (isLogin || path == '/auth-loading' || path == '/unsupported-role') {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/coach',
        builder: (context, state) => const CoachHomeScreen(),
      ),
      GoRoute(
        path: '/coach/athletes/:id',
        builder: (context, state) =>
            CoachAthleteScreen(athleteId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthWelcomeScreen(),
      ),
      GoRoute(
        path: '/login/email',
        builder: (context, state) => const EmailLoginScreen(),
      ),
      GoRoute(
        path: '/auth-loading',
        builder: (context, state) => const AuthStatusScreen(),
      ),
      GoRoute(
        path: '/unsupported-role',
        builder: (context, state) => const AuthStatusScreen(unsupported: true),
      ),
      GoRoute(
        path: AppRoutes.root,
        redirect: (context, state) => AppRoutes.home,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AthleteAppShell(
          navigationShell: navigationShell,
          onLocaleChanged: onLocaleChanged,
          locale: locale,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.training,
                builder: (context, state) => WorkoutScreen(
                  initialHistory: state.uri.queryParameters['tab'] == 'history',
                ),
              ),
              GoRoute(
                path: AppRoutes.workout,
                builder: (context, state) =>
                    WorkoutScreen(workoutId: state.pathParameters['id']),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.nutrition,
                builder: (context, state) => const NutritionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                builder: (context, state) => MoreScreen(
                  locale: locale,
                  onLocaleChanged: onLocaleChanged,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.careTeam,
        builder: (context, state) => const CareTeamScreen(),
      ),
      GoRoute(
        path: AppRoutes.health,
        builder: (context, state) => const HealthScreen(),
      ),
      GoRoute(
        path: AppRoutes.competition,
        builder: (context, state) => const CompetitionScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const PlaceholderScreen(title: 'Profile'),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const PlaceholderScreen(title: 'Settings'),
      ),
      GoRoute(
        path: AppRoutes.records,
        builder: (context, state) => const PlaceholderScreen(title: 'Records'),
      ),
      GoRoute(
        path: AppRoutes.messages,
        builder: (context, state) => const PlaceholderScreen(title: 'Messages'),
      ),
    ],
  );
}
