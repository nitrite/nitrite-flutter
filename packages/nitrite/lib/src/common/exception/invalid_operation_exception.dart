import 'package:nitrite/nitrite.dart';

class InvalidOperationException extends NitriteException {
  InvalidOperationException([String? message]) : super(message);

  @override
  String toString() => message ?? "InvalidOperationException";
}
