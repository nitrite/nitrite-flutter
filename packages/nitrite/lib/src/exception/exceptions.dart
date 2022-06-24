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

class IndexingException extends NitriteException {
  IndexingException(String message, {StackTrace? stackTrace, dynamic cause})
      : super(message, stackTrace: stackTrace, cause: cause);
}

class InvalidIdException extends NitriteException {
  InvalidIdException(String message, {StackTrace? stackTrace, dynamic cause})
      : super(message, stackTrace: stackTrace, cause: cause);
}

class InvalidOperationException extends NitriteException {
  InvalidOperationException(String message,
      {StackTrace? stackTrace, dynamic cause})
      : super(message, stackTrace: stackTrace, cause: cause);
}

class NitriteIOException extends NitriteException {
  NitriteIOException(String message, {StackTrace? stackTrace, dynamic cause})
      : super(message, stackTrace: stackTrace, cause: cause);
}

class ValidationException extends NitriteException {
  ValidationException(String message, {StackTrace? stackTrace, dynamic cause})
      : super(message, stackTrace: stackTrace, cause: cause);
}

class FilterException extends NitriteException {
  FilterException(String message, {StackTrace? stackTrace, dynamic cause})
      : super(message, stackTrace: stackTrace, cause: cause);
}

class NotIdentifiableException extends NitriteException {
  NotIdentifiableException(String message,
      {StackTrace? stackTrace, dynamic cause})
      : super(message, stackTrace: stackTrace, cause: cause);
}

class UniqueConstraintException extends NitriteException {
  UniqueConstraintException(String message,
      {StackTrace? stackTrace, dynamic cause})
      : super(message, stackTrace: stackTrace, cause: cause);
}

class ObjectMappingException extends NitriteException {
  ObjectMappingException(String message,
      {StackTrace? stackTrace, dynamic cause})
      : super(message, stackTrace: stackTrace, cause: cause);
}

class PluginException extends NitriteException {
  PluginException(String message, {StackTrace? stackTrace, dynamic cause})
      : super(message, stackTrace: stackTrace, cause: cause);
}
