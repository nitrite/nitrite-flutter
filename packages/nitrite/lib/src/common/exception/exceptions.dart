class NitriteException implements Exception {
  final String? message;

  NitriteException([this.message]);

  @override
  String toString() => message ?? "NitriteException";
}

class IndexingException extends NitriteException {
  IndexingException([String? message]) : super(message);

  @override
  String toString() => message ?? "IndexingException";
}

class InvalidIdException extends NitriteException {
  InvalidIdException([String? message]) : super(message);

  @override
  String toString() => message ?? "InvalidIdException";
}

class InvalidOperationException extends NitriteException {
  InvalidOperationException([String? message]) : super(message);

  @override
  String toString() => message ?? "InvalidOperationException";
}

class NitriteIOException extends NitriteException {
  NitriteIOException([String? message]) : super(message);

  @override
  String toString() => message ?? "NitriteIOException";
}

class ValidationException extends NitriteException {
  ValidationException([String? message]) : super(message);

  @override
  String toString() => message ?? "ValidationException";
}

class FilterException extends NitriteException {
  FilterException([String? message]) : super(message);

  @override
  String toString() => message ?? "FilterException";
}

class NotIdentifiableException extends NitriteException {
  NotIdentifiableException([String? message]) : super(message);

  @override
  String toString() => message ?? "NotIdentifiableException";
}

class UniqueConstraintException extends NitriteException {
  UniqueConstraintException([String? message]) : super(message);

  @override
  String toString() => message ?? "UniqueConstraintException";
}

class ObjectMappingException extends NitriteException {
  ObjectMappingException([String? message]) : super(message);

  @override
  String toString() => message ?? "ObjectMappingException";
}
