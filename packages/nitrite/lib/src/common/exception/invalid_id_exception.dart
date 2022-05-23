import 'package:nitrite/nitrite.dart';

class InvalidIdException extends NitriteException {
  InvalidIdException([String? message]) : super(message);

  @override
  String toString() => message ?? "InvalidIdException";
}
