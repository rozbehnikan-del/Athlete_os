import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/mock_nutrition_repository.dart';
import '../domain/entities/meal.dart';
import '../domain/repositories/nutrition_repository.dart';
import '../../auth/application/auth_controller.dart';

final nutritionRepositoryProvider = Provider<NutritionRepository>(
  (ref) => MockNutritionRepository(),
);

final todayMealsProvider = FutureProvider<List<Meal>>((ref) async {
  final user = await ref.watch(authControllerProvider.future);
  if (user == null) return [];
  return ref.watch(nutritionRepositoryProvider).getTodayMeals(user.id);
});
