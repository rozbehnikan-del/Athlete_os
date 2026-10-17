import '../entities/auth_session.dart';
import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthSession> login({required String email, required String password});
  Future<AuthUser> getCurrentUser();
  Future<void> logout();
  Future<String?> readAccessToken();
}
