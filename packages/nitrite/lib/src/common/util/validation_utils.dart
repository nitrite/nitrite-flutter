import 'package:nitrite/nitrite.dart';

extension ValidationUtils<T> on T {
  bool get isNullOrEmpty {
    if (this == null) {
      return true;
    }
    if (this is String) {
      return (this as String).isEmpty;
    }
    if (this is Iterable) {
      return (this as Iterable).isEmpty;
    }
    if (this is Map) {
      return (this as Map).isEmpty;
    }
    return false;
  }

  void notNullOrEmpty(String message) {
    if (isNullOrEmpty) {
      throw ValidationException(message);
    }
  }
}
