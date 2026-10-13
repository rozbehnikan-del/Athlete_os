abstract class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class UnauthorizedOperationException extends AppException {
  const UnauthorizedOperationException(super.message);
}

class RepositoryException extends AppException {
  const RepositoryException(super.message);
}
