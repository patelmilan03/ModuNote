/// Base exception type for all ModuNote domain errors.
/// Subtypes give call-sites enough context to show meaningful messages.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException($message)';
}

/// Thrown when a database operation fails (Drift errors wrapped here).
final class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.cause});
}

/// Thrown when a local file operation fails (audio read/write).
final class FileStorageException extends AppException {
  const FileStorageException(super.message, {super.cause});
}

/// Thrown when a requested entity does not exist.
final class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

/// Thrown when input fails validation.
final class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Thrown by audio/speech services when the platform denies a permission.
final class PermissionException extends AppException {
  const PermissionException(super.message);
}
