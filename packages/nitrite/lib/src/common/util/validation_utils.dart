import 'package:nitrite/nitrite.dart';

extension ValidationUtils<T> on T {
  bool get isNullOrEmpty => this == null || toString().isEmpty;

  void notNullOrEmpty(String message) {
    if (isNullOrEmpty) {
      throw ValidationException(message);
    }
  }
}
