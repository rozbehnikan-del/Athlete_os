import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/application/onboarding_controller.dart';
import '../../app/router/routes.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_theme.dart';
import '../screens/app_screens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AthleteAppShell extends ConsumerStatefulWidget {
  const AthleteAppShell({super.key, required this.onLocaleChanged, required this.locale});
  final ValueChanged<Locale> onLocaleChanged;
  final Locale locale;

  @override
  ConsumerState<AthleteAppShell> createState() => _AthleteAppShellState();
}

class _AthleteAppShellState extends ConsumerState<AthleteAppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final onboarded = ref.watch(onboardingControllerProvider);
    if (!onboarded) {
      return WelcomeScreen(
        onGetStarted: ref.read(onboardingControllerProvider.notifier).complete,
      );
    }
    final destinations = [
      _Destination(l.t('home'), Icons.home_rounded, const HomeScreen()),
      _Destination(l.t('progress'), Icons.show_chart_rounded, const ProgressScreen()),
      _Destination(l.t('train'), Icons.fitness_center_rounded, const WorkoutScreen(), dark: true),
      _Destination(l.t('nutrition'), Icons.restaurant_rounded, const NutritionScreen(), dark: true),
      _Destination(l.t('more'), Icons.grid_view_rounded, MoreScreen(onOpen: _openSecondary, locale: widget.locale, onLocaleChanged: widget.onLocaleChanged)),
    ];
    final size = windowClassOf(context);
    final navItems = [
      for (final item in destinations) NavigationDestination(icon: Icon(item.icon), label: item.label),
    ];

    if (size == WindowClass.compact) {
      final dark = destinations[_index].dark;
      return Scaffold(
        backgroundColor: dark ? AppColors.brandBlack : AppColors.background,
        body: destinations[_index].screen,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          backgroundColor: dark ? AppColors.brandBlack : Colors.white,
          indicatorColor: dark ? Colors.white10 : const Color(0xFFE7FBEF),
          elevation: 0,
          height: 68,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? (dark ? Colors.white : AppColors.textDark) : (dark ? Colors.white54 : AppColors.textMuted),
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            );
          }),
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: navItems,
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: Colors.white,
            selectedIndex: _index,
            extended: size == WindowClass.expanded,
            minExtendedWidth: 220,
            onDestinationSelected: (value) => setState(() => _index = value),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Text('AthleteOS', style: Theme.of(context).textTheme.titleLarge),
            ),
            destinations: [
              for (final item in destinations) NavigationRailDestination(icon: Icon(item.icon), label: Text(item.label)),
            ],
          ),
          const VerticalDivider(width: 1, color: AppColors.line),
          Expanded(child: destinations[_index].screen),
        ],
      ),
    );
  }

  void _openSecondary(Widget screen) {
    switch (screen) {
      case CareTeamScreen():
        context.push(AppRoutes.careTeam);
      case HealthScreen():
        context.push(AppRoutes.health);
      case CompetitionScreen():
        context.push(AppRoutes.competition);
      case PlaceholderScreen(title: 'Profile'):
        context.push(AppRoutes.profile);
      default:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.screen, {this.dark = false});
  final String label;
  final IconData icon;
  final Widget screen;
  final bool dark;
}
