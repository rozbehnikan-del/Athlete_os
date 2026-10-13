import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/screens/app_screens.dart';
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
