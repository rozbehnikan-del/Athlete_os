import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/mock_care_team_repository.dart';
import '../domain/entities/professional.dart';
import '../domain/repositories/care_team_repository.dart';

final careTeamRepositoryProvider = Provider<CareTeamRepository>(
  (ref) => MockCareTeamRepository(),
);

final professionalsProvider = FutureProvider<List<Professional>>(
  (ref) => ref.watch(careTeamRepositoryProvider).getProfessionals('athlete-ali'),
);
