import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_storage.dart';
import 'api_client.dart';
import 'api_config.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);
final apiConfigProvider = Provider<ApiConfig>((ref) => const ApiConfig());
final sessionExpiryProvider = NotifierProvider<SessionExpiry, int>(
  SessionExpiry.new,
);

class SessionExpiry extends Notifier<int> {
  @override
  int build() => 0;

  void notify() => state++;
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    config: ref.watch(apiConfigProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    onUnauthorized: () => ref.read(sessionExpiryProvider.notifier).notify(),
  );
  ref.onDispose(client.close);
  return client;
});
