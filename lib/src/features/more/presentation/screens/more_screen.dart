import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../app/application/app_theme_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/page_shell.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/surface_decoration.dart';
import '../../../auth/application/auth_controller.dart';

// ignore_for_file: deprecated_member_use

class MoreScreen extends ConsumerWidget {
  const MoreScreen({
    super.key,
    required this.locale,
    required this.onLocaleChanged,
  });

  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;

    return PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.more, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 18),
          SectionHeader(title: 'Appearance'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
              ],
              selected: {
                ref.watch(appThemeControllerProvider).asData?.value ??
                    ThemeMode.system,
              },
              onSelectionChanged: (selection) => ref
                  .read(appThemeControllerProvider.notifier)
                  .setThemeMode(selection.single),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: lightBoxDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: l.language),
                RadioListTile<Locale>(
                  value: const Locale('en'),
                  groupValue: locale,
                  onChanged: (value) => onLocaleChanged(value!),
                  title: Text(l.english),
                ),
                RadioListTile<Locale>(
                  value: const Locale('fa'),
                  groupValue: locale,
                  onChanged: (value) => onLocaleChanged(value!),
                  title: Text(l.persian),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            tileColor: Theme.of(context).colorScheme.surface,
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}
