import 'package:nitrite/nitrite.dart';

void validateIterableIndexField(Iterable fieldValue, String field) {
  if (fieldValue.isNotEmpty) {
    for (var value in fieldValue) {
      if (value == null) continue;
      validateArrayIndexItem(value, field);
    }
  }
}

void validateArrayIndexItem(dynamic value, String field) {
  if (value is Iterable) {
    throw InvalidOperationException('Nested iterables are not supported');
  }

  if (value is! Comparable) {
    throw IndexingException('Each value in the iterable field $field must '
        'implement Comparable');
  }
}

void validateStringIterableIndexField(Iterable fieldValue, String field) {
  if (!fieldValue.isNullOrEmpty) {
    for (var value in fieldValue) {
      if (value == null) continue;
      validateStringIterableItem(value, field);
    }
  }
}

void validateStringIterableItem(dynamic value, String field) {
  if (value is! String) {
    throw IndexingException('Each value in the iterable field $field must '
        'be a string');
  }
}

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
