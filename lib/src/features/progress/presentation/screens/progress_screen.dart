import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/benchmark_chart.dart';
import '../../../../core/widgets/page_shell.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/responsive_grid.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/surface_decoration.dart';
import '../../../../core/widgets/tab_selector.dart';
import '../../../../core/widgets/trend_chart.dart';
import '../../domain/progress_metrics.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final wide = windowClassOf(context) != WindowClass.compact;
    return PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.progress, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 14),
          TabSelector(
            labels: [l.overview, l.strength, 'Body', 'Photos'],
            selected: 1,
          ),
          const SizedBox(height: 18),
          ResponsiveGrid(
            columns: wide ? 2 : 1,
            children: [
              _ChartCard(l: l),
              _PhotosCard(l: l),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: lightBoxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: l.compareSimilar),
                const SizedBox(height: 14),
                const BenchmarkChart(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: lightBoxDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.backSquat,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const StatusBadge(label: '6 Months'),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '125 kg  Jun 15, 2026',
          style: TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        const TrendChart(points: strengthPoints),
        const SizedBox(height: 16),
        const _StatTriplet(),
      ],
    ),
  );
}

class _StatTriplet extends StatelessWidget {
  const _StatTriplet();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(
        child: _TinyStat(value: '125 kg', label: 'Current'),
      ),
      Expanded(
        child: _TinyStat(value: '110 kg', label: 'Median\nSimilar Athletes'),
      ),
      Expanded(
        child: _TinyStat(value: '160 kg', label: 'Top 10%'),
      ),
    ],
  );
}

class _TinyStat extends StatelessWidget {
  const _TinyStat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _PhotosCard extends StatelessWidget {
  const _PhotosCard({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: lightBoxDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l.progressPhotos),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(child: _PhotoBox(label: 'June 2026')),
            SizedBox(width: 12),
            Expanded(child: _PhotoBox(label: 'October 2026')),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          children: const [
            StatusBadge(label: 'Front'),
            StatusBadge(label: 'Side'),
            StatusBadge(label: 'Back'),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: l.addProgressPhoto,
            icon: Icons.add_a_photo_rounded,
          ),
        ),
      ],
    ),
  );
}

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: .78,
    child: Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
