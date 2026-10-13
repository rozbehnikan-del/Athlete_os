import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/athlete_avatar.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/widgets/page_shell.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/surface_decoration.dart';
import '../../application/care_team_providers.dart';
import '../../domain/entities/professional.dart';

class CareTeamScreen extends ConsumerWidget {
  const CareTeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final professionals = ref.watch(professionalsProvider);
    return PageShell(
      dark: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.careTeam,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 18),
          ...professionals.when(
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (error, stackTrace) => [
              Text('$error', style: const TextStyle(color: Colors.white)),
            ],
            data: (items) => [for (final p in items) _ProfessionalCard(p: p)],
          ),
          const SizedBox(height: 12),
          MetricCard(
            title: l.nextCheckIn,
            value: 'Mon, Jun 22, 2026',
            icon: Icons.event_rounded,
            dark: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: darkBoxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: l.latestFeedback),
                const SizedBox(height: 10),
                const Text(
                  'Reza Ahmadi  -  2 days ago',
                  style: TextStyle(
                    color: Colors.white60,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Great progress on your squats.\nLet's focus more on conditioning this week.",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: l.viewAllMessages,
                  icon: Icons.chat_bubble_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({required this.p});
  final Professional p;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: darkBoxDecoration(),
        child: Row(
          children: [
            AthleteAvatar(label: p.initials, imagePath: p.imagePath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    p.role,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SecondaryButton(label: l.message, dark: true),
          ],
        ),
      ),
    );
  }
}
