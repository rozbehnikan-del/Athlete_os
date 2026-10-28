import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/application/app_theme_controller.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/figma_v1_tokens.dart';
import '../../auth/application/auth_controller.dart';
import '../application/coach_providers.dart';
import '../domain/coach_models.dart';

/// Figma V1 Coach Dashboard, node 3:3. Roster is live; missing KPI data
/// is intentionally labelled unavailable rather than invented.
class CoachDashboardView extends ConsumerStatefulWidget {
  const CoachDashboardView({super.key});

  @override
  ConsumerState<CoachDashboardView> createState() =>
      _CoachDashboardViewState();
}

class _CoachDashboardViewState extends ConsumerState<CoachDashboardView> {
  final _athletesKey = GlobalKey();

  Future<void> _refresh() async {
    ref.invalidate(coachRosterProvider);
    try {
      await ref.read(coachRosterProvider.future);
    } catch (_) {
      // The roster's AsyncValue renders the retry state.
    }
  }

  void _showAthletes() {
    final target = _athletesKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  void _showProgramming() {
    _showAthletes();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Choose an athlete to build a CrossFit session.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roster = ref.watch(coachRosterProvider);
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      backgroundColor: FigmaV1Tokens.background,
      appBar: wide
          ? null
          : AppBar(
              backgroundColor: FigmaV1Tokens.primary,
              foregroundColor: Colors.white,
              title: const Text('AthleteOS · Coach'),
              actions: [
                _AppearanceAction(
                  onModeChanged: (mode) => ref
                      .read(appThemeControllerProvider.notifier)
                      .setThemeMode(mode),
                ),
                IconButton(
                  tooltip: 'Sign Out',
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                ),
              ],
            ),
      body: Row(
        children: [
          if (wide)
            SizedBox(
              width: 220,
              child: _CoachSidebar(
                onAthletes: _showAthletes,
                onProgramming: _showProgramming,
                onSignOut: () =>
                    ref.read(authControllerProvider.notifier).logout(),
                onModeChanged: (mode) => ref
                    .read(appThemeControllerProvider.notifier)
                    .setThemeMode(mode),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(wide ? 30 : 20),
                children: [
                  const Text(
                    'Good morning, Coach',
                    key: Key('coach-dashboard-heading'),
                    style: TextStyle(
                      color: FigmaV1Tokens.text,
                      fontSize: 30,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    roster.when(
                      loading: () => 'Loading your assigned athletes…',
                      error: (e, _) => 'Roster unavailable',
                      data: (athletes) =>
                          '${athletes.length} assigned athletes · Training metrics not connected',
                    ),
                    style: const TextStyle(
                      color: FigmaV1Tokens.muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _CoachStats(roster: roster),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth >= 730;
                      final athletesPanel = _RosterPanel(
                        key: _athletesKey,
                        roster: roster,
                        onRetry: _refresh,
                        onAthlete: (athlete) =>
                            context.push('/coach/athletes/${athlete.id}'),
                      );
                      const alerts = _AttentionPanel();
                      if (!twoColumns) {
                        return Column(
                          children: [
                            athletesPanel,
                            const SizedBox(height: 16),
                            alerts,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: athletesPanel),
                          const SizedBox(width: 16),
                          const Expanded(child: alerts),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachSidebar extends StatelessWidget {
  const _CoachSidebar({
    required this.onAthletes,
    required this.onProgramming,
    required this.onSignOut,
    required this.onModeChanged,
  });

  final VoidCallback onAthletes;
  final VoidCallback onProgramming;
  final VoidCallback onSignOut;
  final ValueChanged<ThemeMode> onModeChanged;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: FigmaV1Tokens.primary,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AthleteOS',
              style: TextStyle(color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            const Text('COACH',
              style: TextStyle(color: Color(0xFF9BA4AB), fontSize: 10,
                  fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            const _SideItem(title: 'Dashboard', active: true),
            _SideItem(title: 'Athletes', onTap: onAthletes),
            _SideItem(title: 'Programming', onTap: onProgramming),
            const _SideItem(title: 'Library · Soon', enabled: false),
            const _SideItem(title: 'Progress · Soon', enabled: false),
            const Spacer(),
            _AppearanceAction(onModeChanged: onModeChanged),
            _SideItem(title: 'Sign Out', onTap: onSignOut),
          ],
        ),
      ),
    ),
  );
}

class _SideItem extends StatelessWidget {
  const _SideItem({
    required this.title,
    this.onTap,
    this.active = false,
    this.enabled = true,
  });
  final String title;
  final VoidCallback? onTap;
  final bool active;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Material(
      color: active ? const Color(0xFF2A3136) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: active || !enabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(title,
              style: TextStyle(
                color: active ? Colors.white
                    : enabled ? const Color(0xFFB8C0C6)
                        : const Color(0xFF78828A),
                fontSize: 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              )),
          ),
        ),
      ),
    ),
  );
}

class _AppearanceAction extends StatelessWidget {
  const _AppearanceAction({required this.onModeChanged});
  final ValueChanged<ThemeMode> onModeChanged;

  @override
  Widget build(BuildContext context) => PopupMenuButton<ThemeMode>(
    tooltip: 'Appearance',
    icon: const Icon(Icons.brightness_6_outlined,
        color: Colors.white),
    onSelected: onModeChanged,
    itemBuilder: (_) => [
      for (final mode in ThemeMode.values)
        PopupMenuItem(value: mode, child: Text(mode.name)),
    ],
  );
}

class _CoachStats extends StatelessWidget {
  const _CoachStats({required this.roster});
  final AsyncValue<List<CoachAthlete>> roster;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final count = constraints.maxWidth >= 900
          ? 4 : constraints.maxWidth >= 460 ? 2 : 1;
      final width = (constraints.maxWidth - 12 * (count - 1)) / count;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: width,
            child: _StatPanel(
              value: roster.when(
                loading: () => '…',
                error: (e, _) => '—',
                data: (athletes) => '${athletes.length}',
              ),
              label: 'Athletes',
              caption: 'assigned',
            ),
          ),
          SizedBox(
            width: width,
            child: const _StatPanel(
              value: '—', label: 'Training today', caption: 'Not available',
            ),
          ),
          SizedBox(
            width: width,
            child: const _StatPanel(
              value: '—', label: '7-day compliance', caption: 'Not available',
            ),
          ),
          SizedBox(
            width: width,
            child: const _StatPanel(
              value: '—', label: 'Flags', caption: 'Not available',
            ),
          ),
        ],
      );
    },
  );
}

class _StatPanel extends StatelessWidget {
  const _StatPanel({
    required this.value,
    required this.label,
    required this.caption,
  });
  final String value;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) => _CoachPanel(
    padding: const EdgeInsets.all(16),
    child: SizedBox(
      height: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
            style: const TextStyle(color: FigmaV1Tokens.text,
              fontSize: 28, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(label,
            style: const TextStyle(color: FigmaV1Tokens.muted,
              fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(caption,
            style: const TextStyle(color: FigmaV1Tokens.muted, fontSize: 11)),
        ],
      ),
    ),
  );
}

class _RosterPanel extends StatelessWidget {
  const _RosterPanel({
    super.key,
    required this.roster,
    required this.onRetry,
    required this.onAthlete,
  });

  final AsyncValue<List<CoachAthlete>> roster;
  final VoidCallback onRetry;
  final ValueChanged<CoachAthlete> onAthlete;

  @override
  Widget build(BuildContext context) => _CoachPanel(
    padding: const EdgeInsets.all(18),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 390),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today',
            style: TextStyle(color: FigmaV1Tokens.text,
              fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Assigned athletes · today’s status not available yet',
            style: TextStyle(color: FigmaV1Tokens.muted, fontSize: 12)),
          const SizedBox(height: 12),
          roster.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(error is AppException ? error.message :
                    'Could not load athletes. Please try again.'),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
            data: (athletes) => athletes.isEmpty
                ? const Text('No athletes assigned yet.')
                : Column(
                    children: [
                      for (final athlete in athletes)
                        _AthleteRow(athlete: athlete,
                            onTap: () => onAthlete(athlete)),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

class _AthleteRow extends StatelessWidget {
  const _AthleteRow({required this.athlete, required this.onTap});
  final CoachAthlete athlete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = athlete.name.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFDEE2E6),
                child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(color: FigmaV1Tokens.muted,
                    fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(athlete.name,
                      style: const TextStyle(color: FigmaV1Tokens.text,
                        fontSize: 14, fontWeight: FontWeight.w700)),
                    if (athlete.email != null)
                      Text(athlete.email!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: FigmaV1Tokens.muted,
                          fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                color: FigmaV1Tokens.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttentionPanel extends StatelessWidget {
  const _AttentionPanel();

  @override
  Widget build(BuildContext context) => _CoachPanel(
    padding: const EdgeInsets.all(18),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 390),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Needs attention',
            style: TextStyle(color: FigmaV1Tokens.text,
              fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FigmaV1Tokens.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No verified alerts available',
                  style: TextStyle(color: FigmaV1Tokens.text,
                    fontSize: 13, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('Compliance and risk alerts require a connected training analytics endpoint.',
                  style: TextStyle(color: FigmaV1Tokens.muted,
                    fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CoachPanel extends StatelessWidget {
  const _CoachPanel({required this.child, required this.padding});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: FigmaV1Tokens.surface,
      border: Border.all(color: FigmaV1Tokens.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );
}
