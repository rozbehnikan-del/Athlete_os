import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/widgets/page_shell.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/surface_decoration.dart';
import '../../../../core/widgets/tab_selector.dart';

class CompetitionScreen extends StatelessWidget {
  const CompetitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.competition, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 14),
          TabSelector(labels: [l.overview, l.rankings, l.myJourney]),
          const SizedBox(height: 18),
          Container(
            height: 220,
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: Image(
                    image: AssetImage(
                      'assets/images/competition/competition_hero.jpg',
                    ),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
                Positioned.fill(
                  child: Container(color: Colors.black.withValues(alpha: .34)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Text(
                      l.competitionHero,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    Text(
                      l.competitionSub,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 150,
                      child: PrimaryButton(
                        label: l.viewDetails,
                        icon: Icons.arrow_forward_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: lightBoxDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: l.competitiveProfile,
                  trailing: const StatusBadge(label: '72%'),
                ),
                const SizedBox(height: 14),
                const _CompetitionMetric(label: 'Strength', value: .86),
                const _CompetitionMetric(label: 'Conditioning', value: .63),
                const _CompetitionMetric(label: 'Gymnastics', value: .68),
                const _CompetitionMetric(label: 'Mobility', value: .77),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: l.yourRank,
                        value: l.top18,
                        delta: 'up 12%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: MetricCard(
                        title: 'Journey',
                        value: 'Performance',
                        delta: '78% toward Competitive',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitionMetric extends StatelessWidget {
  const _CompetitionMetric({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value,
            color: AppColors.primaryGreen,
            backgroundColor: AppColors.line,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(value * 100).round()}%',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}
