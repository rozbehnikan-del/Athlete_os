import '../../domain/entities/meal.dart';
import '../../domain/repositories/nutrition_repository.dart';

class MockNutritionRepository implements NutritionRepository {
  @override
  Future<List<Meal>> getTodayMeals(String athleteId) async => const [
    Meal('Breakfast', 'Greek Yogurt Bowl', '420 kcal', 'assets/images/nutrition/breakfast.jpg'),
    Meal('Lunch', 'Grilled Chicken & Rice', '520 kcal', 'assets/images/nutrition/lunch.jpg'),
    Meal('Snack', 'Protein Shake', '280 kcal', 'assets/images/nutrition/protein_shake.jpg'),
    Meal('Dinner', 'Salmon, Quinoa, Vegetables', '630 kcal', 'assets/images/nutrition/dinner.jpg'),
  ];
}
