import 'package:nitrite/nitrite.dart';

class IndexingException extends NitriteException {
  IndexingException([String? message]) : super(message);

  @override
  String toString() => message ?? "IndexingException";
}
