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
