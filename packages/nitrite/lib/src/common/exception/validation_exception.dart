import 'package:nitrite/src/common/exception/nitrite_exception.dart';

class ValidationException extends NitriteException {
  ValidationException([String? message]) : super(message);

  @override
  String toString() => message ?? "ValidationException";
}
