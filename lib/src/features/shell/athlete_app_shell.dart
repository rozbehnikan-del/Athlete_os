import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/application/onboarding_controller.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_theme.dart';
import '../onboarding/presentation/screens/welcome_screen.dart';

class AthleteAppShell extends ConsumerStatefulWidget {
  const AthleteAppShell({
    super.key,
    required this.navigationShell,
    required this.onLocaleChanged,
    required this.locale,
  });

  final StatefulNavigationShell navigationShell;
  final ValueChanged<Locale> onLocaleChanged;
  final Locale locale;

  @override
  ConsumerState<AthleteAppShell> createState() => _AthleteAppShellState();
}

class _AthleteAppShellState extends ConsumerState<AthleteAppShell> {
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
      _Destination(l.home, Icons.home_rounded),
      _Destination(l.progress, Icons.show_chart_rounded),
      _Destination(l.train, Icons.fitness_center_rounded, dark: true),
      _Destination(l.nutrition, Icons.restaurant_rounded, dark: true),
      _Destination(l.more, Icons.grid_view_rounded),
    ];
    final size = windowClassOf(context);
    final index = widget.navigationShell.currentIndex;
    final navItems = [
      for (final item in destinations)
        NavigationDestination(icon: Icon(item.icon), label: item.label),
    ];

    if (size == WindowClass.compact) {
      final dark = destinations[index].dark;
      return Scaffold(
        backgroundColor: dark ? AppColors.brandBlack : AppColors.background,
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          backgroundColor: dark ? AppColors.brandBlack : Colors.white,
          indicatorColor: dark ? Colors.white10 : const Color(0xFFE7FBEF),
          elevation: 0,
          height: 68,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected
                  ? (dark ? Colors.white : AppColors.textDark)
                  : (dark ? Colors.white54 : AppColors.textMuted),
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            );
          }),
          onDestinationSelected: _goBranch,
          destinations: navItems,
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: Colors.white,
            selectedIndex: index,
            extended: size == WindowClass.expanded,
            minExtendedWidth: 220,
            onDestinationSelected: _goBranch,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Text(
                'AthleteOS',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            destinations: [
              for (final item in destinations)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1, color: AppColors.line),
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, {this.dark = false});
  final String label;
  final IconData icon;
  final bool dark;
}
