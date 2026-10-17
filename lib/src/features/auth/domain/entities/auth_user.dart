import '../../../../core/auth/user_role.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    this.email,
    this.phone,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String? email;
  final String? phone;
  final String fullName;
  final UserRole role;
  final bool isActive;
}
