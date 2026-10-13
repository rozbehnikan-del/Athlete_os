import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/page_shell.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../../core/widgets/surface_decoration.dart';
import '../../../../core/widgets/tab_selector.dart';
import '../../application/nutrition_providers.dart';
import '../../domain/entities/meal.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final meals = ref.watch(todayMealsProvider);
    return PageShell(
      dark: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.nutrition,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: darkBoxDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1,850',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(color: AppColors.primaryGreen),
                      ),
                      const Text(
                        '/ 2,200 kcal',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _Macro(
                        label: 'Protein',
                        value: '142 / 180 g',
                        progress: .79,
                        color: AppColors.primaryGreen,
                      ),
                      const _Macro(
                        label: 'Carbs',
                        value: '180 / 250 g',
                        progress: .72,
                        color: AppColors.blue,
                      ),
                      const _Macro(
                        label: 'Fat',
                        value: '62 / 70 g',
                        progress: .88,
                        color: AppColors.amber,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const ProgressRing(value: 1850 / 2200, size: 84, dark: true),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TabSelector(labels: [l.today, l.mealPlan], dark: true),
          const SizedBox(height: 14),
          ...meals.when(
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (error, stackTrace) => [
              Text('$error', style: const TextStyle(color: Colors.white)),
            ],
            data: (items) => [for (final meal in items) _MealCard(meal: meal)],
          ),
        ],
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({
    required this.label,
    required this.value,
    required this.progress,
    this.color = AppColors.primaryGreen,
  });
  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          color: color,
          backgroundColor: Colors.white12,
          minHeight: 7,
          borderRadius: BorderRadius.circular(99),
        ),
      ],
    ),
  );
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});
  final Meal meal;

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
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 56,
                child: Image.asset(meal.imagePath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.slot,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    meal.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    meal.kcal,
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: () {}, child: Text(l.markAsEaten)),
          ],
        ),
      ),
    );
  }
}
