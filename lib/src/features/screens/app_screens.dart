import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/athlete_components.dart';
import '../../data/mock_data.dart';

class PageShell extends StatelessWidget {
  const PageShell({super.key, required this.child, this.dark = false});
  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final size = windowClassOf(context);
    return ColoredBox(
      color: dark ? AppColors.brandBlack : AppColors.background,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth(size)),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(size == WindowClass.compact ? AppSpacing.x4 : AppSpacing.x8),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onGetStarted});
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.brandBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/images/onboarding_hero.jpg'),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha: .24))),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xDD071119), AppColors.brandBlack],
                stops: [0.35, 0.72, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _AthleteLogoMark(),
                      const SizedBox(width: 14),
                      Text(l.t('app'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    l.t('heroTitle'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      height: .96,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l.t('heroSubtitle'),
                    style: const TextStyle(
                      color: Color(0xFFC3CAD0),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.22,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(width: double.infinity, child: _OnboardingButton(label: l.t('getStarted'), onPressed: onGetStarted)),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        '${l.t('signinPrompt')} ${l.t('signIn')}',
                        style: const TextStyle(
                          color: Color(0xFFC3CAD0),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

class _AthleteLogoMark extends StatelessWidget {
  const _AthleteLogoMark();
  @override
  Widget build(BuildContext context) => SizedBox(width: 48, height: 32, child: CustomPaint(painter: _LogoPainter()));
}

class _OnboardingButton extends StatelessWidget {
  const _OnboardingButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandBlack,
        minimumSize: const Size(0, 50),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(2, size.height - 3)
      ..lineTo(size.width * .26, 4)
      ..lineTo(size.width * .48, size.height - 3)
      ..lineTo(size.width * .64, 8)
      ..lineTo(size.width - 2, size.height - 3);
    canvas.drawPath(path, p);
    canvas.drawLine(Offset(size.width * .20, size.height - 3), Offset(size.width * .39, size.height * .42), p);
    canvas.drawLine(Offset(size.width * .36, size.height - 3), Offset(size.width * .54, size.height * .42), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final wide = windowClassOf(context) != WindowClass.compact;
    return PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const AthleteAvatar(label: 'A', size: 58, imagePath: 'assets/images/athlete_ali_avatar.jpg', showBorder: false),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.t('goodMorning'), style: const TextStyle(color: Color(0xFF6F7A84), fontSize: 15, fontWeight: FontWeight.w700)),
              Text(l.t('ali'), style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28, height: 1.05)),
            ])),
            IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
          ]),
          const SizedBox(height: 18),
          const _DateSelector(),
          const SizedBox(height: 18),
          const _WorkoutCard(),
          const SizedBox(height: 14),
          const SizedBox(height: 12),
          _Responsive(columns: wide ? 3 : 3, children: [
            MetricCard(title: l.t('nutrition'), value: '1,850 kcal', icon: Icons.local_fire_department_rounded),
            MetricCard(title: l.t('weight'), value: '78.5 kg', delta: '-2.1 kg', icon: Icons.monitor_weight_rounded),
            MetricCard(title: l.t('sleep'), value: '7h 12m', icon: Icons.bedtime_rounded),
          ]),
          if (wide) ...[const SizedBox(height: 18), const _ReadinessCard()],
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector();
  @override
  Widget build(BuildContext context) {
    final days = ['Mon\n13', 'Tue\n14', 'Wed\n15', 'Thu\n16', 'Fri\n17', 'Sat\n18'];
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => Container(
          width: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: i == 2 ? AppColors.brandBlack : Colors.white, borderRadius: BorderRadius.circular(AppRadii.md), border: Border.all(color: AppColors.line)),
          child: Text(days[i], textAlign: TextAlign.center, style: TextStyle(color: i == 2 ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.xl), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.t('todaysWorkout'), style: Theme.of(context).textTheme.titleLarge),
            Text('${l.t('strength')} (${l.t('lowerBody')})', style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ])),
          TextButton(onPressed: () {}, child: Text(l.t('viewPlan'), style: const TextStyle(fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(children: [
            for (var i = 0; i < exercises.length; i++) _ExerciseLine(exercise: exercises[i], complete: i == 0),
          ])),
          const SizedBox(width: 8),
          const ProgressRing(value: .75, size: 58),
        ]),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: PrimaryButton(label: l.t('startWorkout'), icon: Icons.arrow_forward_rounded)),
      ]),
    );
  }
}

class _ExerciseLine extends StatelessWidget {
  const _ExerciseLine({required this.exercise, this.complete = false});
  final Exercise exercise;
  final bool complete;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Image.asset(exercise.imagePath, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(exercise.name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800)),
          Text(exercise.detail, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 12)),
        ])),
        Icon(complete ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: complete ? AppColors.primaryGreen : AppColors.textMuted, size: 22),
      ]),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.xl), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(title: l.t('readiness'), trailing: const ProgressRing(value: .82)),
        const SizedBox(height: 18),
        for (final item in ['Sleep', 'Energy', 'Soreness', 'Stress', 'Pain'])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [Expanded(child: Text(item, style: const TextStyle(fontWeight: FontWeight.w700))), const StatusBadge(label: 'Good')]),
          ),
      ]),
    );
  }
}

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PageShell(
      dark: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.t('backSquat'), style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white)),
        const SizedBox(height: 14),
        _Tabs(labels: [l.t('overview'), l.t('history'), l.t('video'), l.t('notes')], dark: true),
        const SizedBox(height: 18),
        Container(
          height: 220,
          decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(AppRadii.xl)),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            const Positioned.fill(
              child: Image(
                image: AssetImage('assets/images/exercises/back_squat_hero.jpg'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            Positioned.fill(child: Container(color: Colors.black.withValues(alpha: .20))),
            Center(child: IconButton.filled(onPressed: () {}, icon: const Icon(Icons.play_arrow_rounded), style: IconButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: AppColors.brandBlack))),
            Positioned(left: 16, bottom: 16, child: Wrap(spacing: 8, children: [StatusBadge(label: l.t('strength'), dark: true), StatusBadge(label: l.t('compound'), dark: true)])),
            Positioned(left: 16, bottom: 58, child: Text(l.t('backSquat'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white))),
          ]),
        ),
        const SizedBox(height: 18),
        Wrap(spacing: 8, children: [StatusBadge(label: l.t('coachControlled'), color: AppColors.amber, dark: true, icon: Icons.lock_rounded), StatusBadge(label: l.t('verified'), dark: true, icon: Icons.verified_rounded)]),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(AppRadii.lg)),
          child: Column(children: [
            Row(children: [Expanded(child: Text(l.t('set'), style: _tableHead)), Expanded(child: Text(l.t('reps'), style: _tableHead)), Expanded(child: Text(l.t('weight'), style: _tableHead)), const SizedBox(width: 34)]),
            const Divider(color: Colors.white12),
            for (final set in exercises.first.sets) _SetRow(set: set),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: SecondaryButton(label: l.t('addSet'), dark: true)), const SizedBox(width: 12), Expanded(child: PrimaryButton(label: l.t('completeSet'), icon: Icons.check_rounded))]),
      ]),
    );
  }
}

const _tableHead = TextStyle(color: Colors.white54, fontWeight: FontWeight.w800);

class _SetRow extends StatelessWidget {
  const _SetRow({required this.set});
  final ExerciseSet set;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(children: [
        Expanded(child: Text('${set.set}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
        Expanded(child: Text('${set.reps}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
        Expanded(child: Text(set.weight, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
        Icon(set.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: set.completed ? AppColors.primaryGreen : Colors.white24),
      ]),
    );
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final wide = windowClassOf(context) != WindowClass.compact;
    return PageShell(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.t('progress'), style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 14),
      _Tabs(labels: [l.t('overview'), l.t('strength'), 'Body', 'Photos'], selected: 1),
      const SizedBox(height: 18),
      _Responsive(columns: wide ? 2 : 1, children: [
        _ChartCard(l: l),
        _PhotosCard(l: l),
      ]),
      const SizedBox(height: 18),
      Container(padding: const EdgeInsets.all(18), decoration: _lightBox(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(title: l.t('compareSimilar')),
        const SizedBox(height: 14),
        const BenchmarkChart(),
      ])),
    ]));
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.l});
  final AppLocalizations l;
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(18), decoration: _lightBox(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(l.t('backSquat'), style: Theme.of(context).textTheme.headlineSmall)), const StatusBadge(label: '6 Months')]),
      const SizedBox(height: 8),
      const Text('125 kg  Jun 15, 2026', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
      const SizedBox(height: 18),
      const TrendChart(points: strengthPoints),
      const SizedBox(height: 16),
      const _StatTriplet(),
    ]));
  }
}

class _StatTriplet extends StatelessWidget {
  const _StatTriplet();
  @override
  Widget build(BuildContext context) => const Row(children: [
    Expanded(child: _TinyStat(value: '125 kg', label: 'Current')),
    Expanded(child: _TinyStat(value: '110 kg', label: 'Median\nSimilar Athletes')),
    Expanded(child: _TinyStat(value: '160 kg', label: 'Top 10%')),
  ]);
}

class _TinyStat extends StatelessWidget {
  const _TinyStat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: Theme.of(context).textTheme.titleLarge), Text(label, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700))]);
}

class _PhotosCard extends StatelessWidget {
  const _PhotosCard({required this.l});
  final AppLocalizations l;
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(18), decoration: _lightBox(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(title: l.t('progressPhotos')),
      const SizedBox(height: 12),
      Row(children: const [Expanded(child: _PhotoBox(label: 'June 2026')), SizedBox(width: 12), Expanded(child: _PhotoBox(label: 'October 2026'))]),
      const SizedBox(height: 14),
      Wrap(spacing: 8, children: const [StatusBadge(label: 'Front'), StatusBadge(label: 'Side'), StatusBadge(label: 'Back')]),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: PrimaryButton(label: l.t('addProgressPhoto'), icon: Icons.add_a_photo_rounded)),
    ]));
  }
}

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => AspectRatio(aspectRatio: .78, child: Container(alignment: Alignment.bottomCenter, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(AppRadii.md)), child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))));
}

class CareTeamScreen extends StatelessWidget {
  const CareTeamScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PageShell(dark: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.t('careTeam'), style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white)),
      const SizedBox(height: 18),
      for (final p in professionals) _ProfessionalCard(p: p),
      const SizedBox(height: 12),
      MetricCard(title: l.t('nextCheckIn'), value: 'Mon, Jun 22, 2026', icon: Icons.event_rounded, dark: true),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(18), decoration: _darkBox(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(title: l.t('latestFeedback')),
        const SizedBox(height: 10),
        const Text('Reza Ahmadi  -  2 days ago', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text("Great progress on your squats.\nLet's focus more on conditioning this week.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, height: 1.45)),
        const SizedBox(height: 14),
        PrimaryButton(label: l.t('viewAllMessages'), icon: Icons.chat_bubble_rounded),
      ])),
    ]));
  }
}

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({required this.p});
  final Professional p;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(padding: const EdgeInsets.all(16), decoration: _darkBox(), child: Row(children: [
        AthleteAvatar(label: p.initials, imagePath: p.imagePath),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)), Text(p.role, style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w700))])),
        SecondaryButton(label: l.t('message'), dark: true),
      ])),
    );
  }
}

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final wide = windowClassOf(context) != WindowClass.compact;
    return PageShell(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.t('health'), style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 14),
      _Tabs(labels: [l.t('overview'), l.t('labResults'), l.t('injury'), l.t('vitals')]),
      const SizedBox(height: 18),
      _Responsive(columns: wide ? 3 : 2, children: [
        MetricCard(title: l.t('overallHealth'), value: l.t('good'), icon: Icons.health_and_safety_rounded),
        MetricCard(title: l.t('labResults'), value: '2 new', delta: l.t('needsReview'), icon: Icons.science_rounded),
        MetricCard(title: l.t('recovery'), value: '72%', icon: Icons.favorite_rounded),
        const MetricCard(title: 'HRV', value: '58 ms', icon: Icons.monitor_heart_rounded),
        MetricCard(title: l.t('sleep'), value: '7h 12m', icon: Icons.bedtime_rounded),
        MetricCard(title: l.t('stress'), value: 'Low', icon: Icons.spa_rounded),
      ]),
      const SizedBox(height: 18),
      Container(padding: const EdgeInsets.all(18), decoration: _lightBox(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(title: l.t('latestLabReport'), trailing: StatusBadge(label: l.t('reviewed'), icon: Icons.check_rounded)),
        const SizedBox(height: 8),
        const Text('Blood Test  -  Jun 10, 2026\nReviewed by Dr. Hossein', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700, height: 1.5)),
        const SizedBox(height: 14),
        PrimaryButton(label: l.t('uploadNewReport'), icon: Icons.upload_file_rounded),
      ])),
    ]));
  }
}

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PageShell(dark: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.t('nutrition'), style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white)),
      const SizedBox(height: 18),
      Container(padding: const EdgeInsets.all(18), decoration: _darkBox(), child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('1,850', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppColors.primaryGreen)),
          const Text('/ 2,200 kcal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          const _Macro(label: 'Protein', value: '142 / 180 g', progress: .79, color: AppColors.primaryGreen),
          const _Macro(label: 'Carbs', value: '180 / 250 g', progress: .72, color: AppColors.blue),
          const _Macro(label: 'Fat', value: '62 / 70 g', progress: .88, color: AppColors.amber),
        ])),
        const SizedBox(width: 12),
        const ProgressRing(value: 1850 / 2200, size: 84, dark: true),
      ])),
      const SizedBox(height: 18),
      _Tabs(labels: [l.t('today'), l.t('mealPlan')], dark: true),
      const SizedBox(height: 14),
      for (final meal in meals) _MealCard(meal: meal),
    ]));
  }
}

class _Macro extends StatelessWidget {
  const _Macro({required this.label, required this.value, required this.progress, this.color = AppColors.primaryGreen});
  final String label;
  final String value;
  final double progress;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(children: [Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))), Text(value, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700))]), const SizedBox(height: 8), LinearProgressIndicator(value: progress, color: color, backgroundColor: Colors.white12, minHeight: 7, borderRadius: BorderRadius.circular(99))]));
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});
  final Meal meal;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(padding: const EdgeInsets.all(16), decoration: _darkBox(), child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 64,
            height: 56,
            child: Image.asset(meal.imagePath, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(meal.slot, style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w700)), Text(meal.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)), Text(meal.kcal, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w800))])),
        TextButton(onPressed: () {}, child: Text(l.t('markAsEaten'))),
      ])),
    );
  }
}

class CompetitionScreen extends StatelessWidget {
  const CompetitionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PageShell(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.t('competition'), style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 14),
      _Tabs(labels: [l.t('overview'), l.t('rankings'), l.t('myJourney')]),
      const SizedBox(height: 18),
      Container(height: 220, clipBehavior: Clip.antiAlias, padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(AppRadii.xl)), child: Stack(children: [
        const Positioned.fill(
          child: Image(
            image: AssetImage('assets/images/competition/competition_hero.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        Positioned.fill(child: Container(color: Colors.black.withValues(alpha: .34))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Spacer(),
          Text(l.t('competitionHero'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
          Text(l.t('competitionSub'), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(width: 150, child: PrimaryButton(label: l.t('viewDetails'), icon: Icons.arrow_forward_rounded)),
        ]),
      ])),
      const SizedBox(height: 18),
      Container(padding: const EdgeInsets.all(18), decoration: _lightBox(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(title: l.t('competitiveProfile'), trailing: const StatusBadge(label: '72%')),
        const SizedBox(height: 14),
        const _CompetitionMetric(label: 'Strength', value: .86),
        const _CompetitionMetric(label: 'Conditioning', value: .63),
        const _CompetitionMetric(label: 'Gymnastics', value: .68),
        const _CompetitionMetric(label: 'Mobility', value: .77),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: MetricCard(title: l.t('yourRank'), value: l.t('top18'), delta: 'up 12%')), const SizedBox(width: 12), const Expanded(child: MetricCard(title: 'Journey', value: 'Performance', delta: '78% toward Competitive'))]),
      ])),
    ]));
  }
}

class _CompetitionMetric extends StatelessWidget {
  const _CompetitionMetric({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [SizedBox(width: 104, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))), Expanded(child: LinearProgressIndicator(value: value, color: AppColors.primaryGreen, backgroundColor: AppColors.line, minHeight: 8, borderRadius: BorderRadius.circular(99))), const SizedBox(width: 12), Text('${(value * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w900))]));
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.onOpen, required this.locale, required this.onLocaleChanged});
  final ValueChanged<Widget> onOpen;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = [
      (l.t('careTeam'), Icons.groups_rounded, const CareTeamScreen()),
      (l.t('health'), Icons.health_and_safety_rounded, const HealthScreen()),
      (l.t('competition'), Icons.emoji_events_rounded, const CompetitionScreen()),
      ('Records', Icons.workspace_premium_rounded, const PlaceholderScreen(title: 'Records')),
      ('Messages', Icons.chat_bubble_rounded, const PlaceholderScreen(title: 'Messages')),
      ('Profile', Icons.person_rounded, const PlaceholderScreen(title: 'Profile')),
    ];
    return PageShell(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.t('more'), style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 18),
      for (final item in items)
        Padding(padding: const EdgeInsets.only(bottom: 10), child: ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)), tileColor: Colors.white, leading: Icon(item.$2), title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w800)), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => onOpen(item.$3))),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(18), decoration: _lightBox(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(title: l.t('language')),
        RadioListTile<Locale>(value: const Locale('en'), groupValue: locale, onChanged: (v) => onLocaleChanged(v!), title: Text(l.t('english'))),
        RadioListTile<Locale>(value: const Locale('fa'), groupValue: locale, onChanged: (v) => onLocaleChanged(v!), title: Text(l.t('persian'))),
      ])),
    ]));
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => PageShell(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineLarge), const SizedBox(height: 18), const MetricCard(title: 'Athlete-owned', value: 'Ready'), const SizedBox(height: 12), const MetricCard(title: 'Professional-controlled', value: 'Locked', delta: 'Coach controlled')]));
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.labels, this.selected = 0, this.dark = false});
  final List<String> labels;
  final int selected;
  final bool dark;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: i == selected ? (dark ? Colors.white : AppColors.brandBlack) : (dark ? Colors.white10 : Colors.white),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: dark ? Colors.white12 : AppColors.line),
          ),
          child: Text(labels[i], style: TextStyle(color: i == selected ? (dark ? AppColors.brandBlack : Colors.white) : (dark ? Colors.white70 : AppColors.textMuted), fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _Responsive extends StatelessWidget {
  const _Responsive({required this.children, required this.columns});
  final List<Widget> children;
  final int columns;
  @override
  Widget build(BuildContext context) {
    if (columns == 1) return Column(children: [for (final child in children) Padding(padding: const EdgeInsets.only(bottom: 12), child: child)]);
    return LayoutBuilder(builder: (context, constraints) {
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(spacing: 12, runSpacing: 12, children: [for (final child in children) SizedBox(width: width, child: child)]);
    });
  }
}

BoxDecoration _lightBox() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.xl), border: Border.all(color: AppColors.line));
BoxDecoration _darkBox() => BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(AppRadii.lg), border: Border.all(color: Colors.white10));
