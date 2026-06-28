/// Base class for all Nitrite exceptions.
class NitriteException implements Exception {
  final String message;
  final StackTrace stackTrace;
  final dynamic cause;

  NitriteException(this.message, {StackTrace? stackTrace, this.cause})
      : stackTrace = stackTrace ?? StackTrace.current;

  @override
  String toString() => '${runtimeType.toString()}: $message\n$stackTrace'
      '${cause != null ? "\nCaused by: $cause" : ""}';
}

/// Exception thrown when there is an error with indexing in Nitrite.
class IndexingException extends NitriteException {
  IndexingException(super.message, {super.stackTrace, super.cause});
}

/// Exception thrown when an invalid ID is encountered.
class InvalidIdException extends NitriteException {
  InvalidIdException(super.message, {super.stackTrace, super.cause});
}

/// Exception thrown when an invalid operation is performed.
class InvalidOperationException extends NitriteException {
  InvalidOperationException(super.message, {super.stackTrace, super.cause});
}

/// Exception thrown when there is an IO error while performing an operation
/// on Nitrite database.
class NitriteIOException extends NitriteException {
  NitriteIOException(super.message, {super.stackTrace, super.cause});
}

/// Exception thrown when a validation error occurs.
class ValidationException extends NitriteException {
  ValidationException(super.message, {super.stackTrace, super.cause});
}

/// Exception thrown during find operations due to invalid filter expression.
class FilterException extends NitriteException {
  FilterException(super.message, {super.stackTrace, super.cause});
}

/// Exception thrown when an object cannot be identified.
class NotIdentifiableException extends NitriteException {
  NotIdentifiableException(super.message, {super.stackTrace, super.cause});
}

/// Exception thrown when a unique constraint is violated.
class UniqueConstraintException extends NitriteException {
  UniqueConstraintException(super.message, {super.stackTrace, super.cause});
}

/// Exception thrown when there is an error mapping an object to a
/// document or vice versa.
class ObjectMappingException extends NitriteException {
  ObjectMappingException(super.message, {super.stackTrace, super.cause});
}

/// Exception thrown when a Nitrite plugin encounters an error.
class PluginException extends NitriteException {
  PluginException(super.message, {super.stackTrace, super.cause});
}

/// Exception thrown when a security violation occurs in Nitrite.
class NitriteSecurityException extends NitriteException {
  NitriteSecurityException(super.message, {super.stackTrace, super.cause});
}

/// Exception thrown when there is an error during database migration.
class MigrationException extends NitriteException {
  MigrationException(super.message, {super.stackTrace, super.cause});
}

/// Exception thrown when an error occurs during a transaction.
class TransactionException extends NitriteException {
  TransactionException(super.message, {super.stackTrace, super.cause});
}
