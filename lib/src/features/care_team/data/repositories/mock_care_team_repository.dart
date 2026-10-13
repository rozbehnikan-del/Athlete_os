import '../../domain/entities/professional.dart';
import '../../domain/repositories/care_team_repository.dart';

class MockCareTeamRepository implements CareTeamRepository {
  @override
  Future<List<Professional>> getProfessionals(String athleteId) async => const [
    Professional('Reza Ahmadi', 'Head Coach', 'RA', 'assets/images/professionals/coach_reza.jpg'),
    Professional('Sara Karimi', 'Nutritionist', 'SK', 'assets/images/professionals/nutritionist_sara.jpg'),
    Professional('Dr. Hossein', 'Sports Doctor', 'DH', 'assets/images/professionals/doctor_hossein.jpg'),
  ];
}
