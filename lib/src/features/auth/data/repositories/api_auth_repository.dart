import '../../../../core/api/api_client.dart';
import '../../../../core/auth/token_storage.dart';
import '../../../../core/auth/user_role.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client, this._storage);
  final ApiClient _client;
  final TokenStorage _storage;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = _data(
        await _client.post(
          '/v1/auth/login',
          body: {'email': email, 'password': password},
        ),
      );
      final token = _string(data, 'access_token');
      final type = _string(data, 'token_type');
      final expires = data['expires_in'];
      if (type.toLowerCase() != 'bearer' || expires is! int || expires <= 0) {
        throw const RepositoryException(
          'Server returned malformed session data.',
        );
      }
      await _storage.saveAccessToken(token);
      try {
        final user = await getCurrentUser();
        return AuthSession(
          accessToken: token,
          tokenType: type,
          expiresIn: expires,
          user: user,
        );
      } catch (_) {
        await _storage.deleteAccessToken();
        rethrow;
      }
    } on SessionExpiredException {
      throw const RepositoryException('Email or password is incorrect.');
    } on RepositoryException {
      throw const RepositoryException('Unable to sign in. Please try again.');
    }
  }

  @override
  Future<AuthUser> getCurrentUser() async {
    final data = _data(await _client.get('/v1/auth/me'));
    final role = _string(data, 'role');
    final roles = UserRole.values.where((value) => value.name == role);
    final active = data['is_active'];
    if (roles.isEmpty || active is! bool) {
      throw const RepositoryException('Server returned malformed user data.');
    }
    return AuthUser(
      id: _string(data, 'id'),
      email: _optionalString(data, 'email'),
      phone: _optionalString(data, 'phone'),
      fullName: _string(data, 'full_name'),
      role: roles.single,
      isActive: active,
    );
  }

  @override
  Future<void> logout() => _storage.deleteAccessToken();
  @override
  Future<String?> readAccessToken() => _storage.readAccessToken();

  Map<String, dynamic> _data(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw const RepositoryException('Server returned malformed auth data.');
  }

  String _string(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw const RepositoryException('Server returned malformed auth data.');
  }

  String? _optionalString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null || value is String) return value as String?;
    throw const RepositoryException('Server returned malformed user data.');
  }
}
