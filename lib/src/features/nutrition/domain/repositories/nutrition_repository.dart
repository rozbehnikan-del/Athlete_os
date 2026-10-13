import '../entities/meal.dart';

abstract interface class NutritionRepository {
  Future<List<Meal>> getTodayMeals(String athleteId);
}
