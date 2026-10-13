import '../entities/professional.dart';

abstract interface class CareTeamRepository {
  Future<List<Professional>> getProfessionals(String athleteId);
}
