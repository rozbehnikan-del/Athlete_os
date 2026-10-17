import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/errors/app_exception.dart';
import '../data/repositories/api_auth_repository.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ApiAuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  ),
);
final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    ref.listen(sessionExpiryProvider, (_, _) {
      state = const AsyncData(null);
    });
    final repository = ref.watch(authRepositoryProvider);
    final token = await repository.readAccessToken();
    if (token == null || token.isEmpty) return null;
    try {
      return await repository.getCurrentUser();
    } on SessionExpiredException {
      await repository.logout();
      return null;
    }
  }

  Future<void> login({required String email, required String password}) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      return session.user;
    });
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
      state = const AsyncData(null);
    } catch (error, stack) {
      state = AsyncError(
        const RepositoryException(
          'Could not clear your session. Please try again.',
        ),
        stack,
      );
    }
  }
}
