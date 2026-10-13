import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/mock_nutrition_repository.dart';
import '../domain/entities/meal.dart';
import '../domain/repositories/nutrition_repository.dart';

final nutritionRepositoryProvider = Provider<NutritionRepository>(
  (ref) => MockNutritionRepository(),
);

final todayMealsProvider = FutureProvider<List<Meal>>(
  (ref) => ref.watch(nutritionRepositoryProvider).getTodayMeals('athlete-ali'),
);
