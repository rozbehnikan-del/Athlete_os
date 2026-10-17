import 'package:athlete_os/src/core/auth/token_storage.dart';
import 'package:athlete_os/src/core/auth/user_role.dart';
import 'package:athlete_os/src/features/auth/domain/entities/auth_session.dart';
import 'package:athlete_os/src/features/auth/domain/entities/auth_user.dart';
import 'package:athlete_os/src/features/auth/domain/repositories/auth_repository.dart';

const testAthlete = AuthUser(
  id: '22222222-2222-4222-8222-222222222222',
  email: 'ali@athleteos.local',
  fullName: 'Ali',
  role: UserRole.athlete,
  isActive: true,
);

class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage([this.token]);
  String? token;
  @override
  Future<String?> readAccessToken() async => token;
  @override
  Future<void> saveAccessToken(String token) async => this.token = token;
  @override
  Future<void> deleteAccessToken() async => token = null;
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.token = 'test-token',
    this.user = testAthlete,
    this.failure,
  });
  String? token;
  final AuthUser user;
  final Exception? failure;
  int currentUserCalls = 0;

  @override
  Future<AuthUser> getCurrentUser() async {
    currentUserCalls++;
    if (failure != null) throw failure!;
    return user;
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (failure != null) throw failure!;
    token = 'test-token';
    return AuthSession(
      accessToken: token!,
      tokenType: 'bearer',
      expiresIn: 3600,
      user: user,
    );
  }

  @override
  Future<void> logout() async => token = null;
  @override
  Future<String?> readAccessToken() async => token;
}
