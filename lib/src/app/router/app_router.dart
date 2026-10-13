import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

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
}) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
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
