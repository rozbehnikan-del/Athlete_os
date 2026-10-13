import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/care_team/presentation/screens/care_team_screen.dart';
import '../../features/competition/presentation/screens/competition_screen.dart';
import '../../features/health/presentation/screens/health_screen.dart';
import '../../features/more/presentation/screens/more_screen.dart';
import '../../features/shell/athlete_app_shell.dart';
import 'routes.dart';

GoRouter createAppRouter({
  required Locale locale,
  required ValueChanged<Locale> onLocaleChanged,
}) {
  return GoRouter(
    initialLocation: AppRoutes.root,
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => AthleteAppShell(
          onLocaleChanged: onLocaleChanged,
          locale: locale,
        ),
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
    ],
  );
}
