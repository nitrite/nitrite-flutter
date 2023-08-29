import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';

/// @nodoc
void validateIterableIndexField(Iterable fieldValue, String field) {
  if (fieldValue.isNotEmpty) {
    for (var value in fieldValue) {
      if (value == null) continue;
      validateArrayIndexItem(value, field);
    }
  }
}

/// @nodoc
void validateArrayIndexItem(dynamic value, String field) {
  if (value is Iterable) {
    throw InvalidOperationException('Nested iterables are not supported');
  }

  if (value is! Comparable) {
    throw IndexingException('Each value in the iterable field $field must '
        'implement Comparable');
  }
}

/// @nodoc
void validateStringIterableIndexField(Iterable fieldValue, String field) {
  if (!fieldValue.isNullOrEmpty) {
    for (var value in fieldValue) {
      if (value == null) continue;
      validateStringIterableItem(value, field);
    }
  }
}

/// @nodoc
void validateStringIterableItem(dynamic value, String field) {
  if (value is! String) {
    throw IndexingException('Each value in the iterable field $field must '
        'be a string');
  }
}

/// @nodoc
void validateProjectionType<T>(NitriteMapper nitriteMapper) {
  T? value;
  try {
    value = newInstance<T>(nitriteMapper);
  } catch (e, s) {
    throw ValidationException("Invalid projection type",
        cause: e, stackTrace: s);
  }

  if (value == null) {
    throw ValidationException("Invalid projection type");
  }

  Document? document;
  try {
    document = nitriteMapper.tryConvert<Document, T>(value);
  } catch (e, s) {
    throw ValidationException("Invalid projection type",
        cause: e, stackTrace: s);
  }

  if (document == null || document.size == 0) {
    throw ValidationException("Cannot project to empty type ${T.toString()}");
  }
}

/// @nodoc
void validateRepositoryType<T>(NitriteMapper nitriteMapper) {
  dynamic value;
  try {
    value = newInstance<T>(nitriteMapper);
    if (value == null) {
      throw ValidationException(
          "Cannot create new instance of type ${T.toString()}");
    }

    var document = nitriteMapper.tryConvert<Document, T>(value);
    if (document == null || document.size == 0) {
      throw ValidationException(
          "Cannot convert to document from type ${T.toString()}");
    }
  } catch (e, s) {
    throw ValidationException("Invalid repository type",
        cause: e, stackTrace: s);
  }
}

/// @nodoc
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

  void notContainsNull(String message) {
    if (this is List) {
      if ((this as List).contains(null)) {
        throw ValidationException(message);
      }
    } else if (this is Set) {
      if ((this as Set).contains(null)) {
        throw ValidationException(message);
      }
    }
  }
}
