import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/widgets/page_shell.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/surface_decoration.dart';

// ignore_for_file: deprecated_member_use

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
  });
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final items = [
      (l.careTeam, Icons.groups_rounded, AppRoutes.careTeam),
      (l.health, Icons.health_and_safety_rounded, AppRoutes.health),
      (l.competition, Icons.emoji_events_rounded, AppRoutes.competition),
      ('Records', Icons.workspace_premium_rounded, AppRoutes.records),
      ('Messages', Icons.chat_bubble_rounded, AppRoutes.messages),
      ('Profile', Icons.person_rounded, AppRoutes.profile),
    ];
    return PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.more, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 18),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                tileColor: Colors.white,
                leading: Icon(item.$2),
                title: Text(
                  item.$1,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(item.$3),
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: lightBoxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: l.language),
                RadioListTile<Locale>(
                  value: const Locale('en'),
                  groupValue: locale,
                  onChanged: (v) => onLocaleChanged(v!),
                  title: Text(l.english),
                ),
                RadioListTile<Locale>(
                  value: const Locale('fa'),
                  groupValue: locale,
                  onChanged: (v) => onLocaleChanged(v!),
                  title: Text(l.persian),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => PageShell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 18),
        const MetricCard(title: 'Athlete-owned', value: 'Ready'),
        const SizedBox(height: 12),
        const MetricCard(
          title: 'Professional-controlled',
          value: 'Locked',
          delta: 'Coach controlled',
        ),
      ],
    ),
  );
}
