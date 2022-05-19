import 'package:nitrite/nitrite.dart';

class NitriteIOException extends NitriteException {
  NitriteIOException([String? message]) : super(message);

  @override
  String toString() => message ?? "NitriteIOException";
}
