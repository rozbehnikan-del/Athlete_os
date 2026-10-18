import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/widgets/page_shell.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/responsive_grid.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/surface_decoration.dart';
import '../../../../core/widgets/tab_selector.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final wide = windowClassOf(context) != WindowClass.compact;
    return PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.health, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 14),
          TabSelector(labels: [l.overview, l.labResults, l.injury, l.vitals]),
          const SizedBox(height: 18),
          ResponsiveGrid(
            columns: wide ? 3 : 2,
            children: [
              MetricCard(
                title: l.overallHealth,
                value: l.good,
                icon: Icons.health_and_safety_rounded,
              ),
              MetricCard(
                title: l.labResults,
                value: '2 new',
                delta: l.needsReview,
                icon: Icons.science_rounded,
              ),
              MetricCard(
                title: l.recovery,
                value: '72%',
                icon: Icons.favorite_rounded,
              ),
              const MetricCard(
                title: 'HRV',
                value: '58 ms',
                icon: Icons.monitor_heart_rounded,
              ),
              MetricCard(
                title: l.sleep,
                value: '7h 12m',
                icon: Icons.bedtime_rounded,
              ),
              MetricCard(
                title: l.stress,
                value: 'Low',
                icon: Icons.spa_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: lightBoxDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: l.latestLabReport,
                  trailing: StatusBadge(
                    label: l.reviewed,
                    icon: Icons.check_rounded,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Blood Test  -  Jun 10, 2026\nReviewed by Dr. Hossein',
                  style: TextStyle(
                    color: Color(0xFF68737D),
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: l.uploadNewReport,
                  icon: Icons.upload_file_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
