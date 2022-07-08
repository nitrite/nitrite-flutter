import 'package:collection/collection.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/number_utils.dart' as numbers;
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:nitrite/src/repository/entity.dart';

void blackHole(dynamic _) {}

bool isSubtype<S, T>() => <S>[] is List<T>;

String getKeyName(String collectionName) {
  if (collectionName.contains(keyObjSeparator)) {
    var split = collectionName.split(keyObjSeparator);
    return split[1];
  }
  throw ValidationException("$collectionName is not a valid keyed "
      "object repository");
}

String getKeyedRepositoryType(String collectionName) {
  if (collectionName.contains(keyObjSeparator)) {
    var split = collectionName.split(keyObjSeparator);
    return split[0];
  }
  throw ValidationException("$collectionName is not a valid keyed "
      "object repository");
}

bool deepEquals(o1, o2) {
  if (o1 == null && o2 == null) {
    return true;
  } else if (o1 == null || o2 == null) {
    return false;
  }

  if (identical(o1, o2)) {
    // if reference equal send true
    return true;
  }

  if (o1 is num && o2 is num) {
    if (o1.runtimeType != o2.runtimeType) {
      return false;
    }

    // cast to Number and take care of boxing and compare
    return numbers.compare(o1, o2) == 0;
  } else if (o1 is Iterable && o2 is Iterable) {
    return IterableEquality().equals(o1, o2);
  } else if (o1 is Map && o2 is Map) {
    return MapEquality().equals(o1, o2);
  } else {
    // generic check
    return o1.runtimeType == o2.runtimeType && o1 == o2;
  }
}

int compare(Comparable first, Comparable second) {
  if (first is num && second is num) {
    var result = numbers.compare(first, second);
    if (first.runtimeType != second.runtimeType) {
      if (result == 0) return 1;
    }
    return result;
  }
  return first.compareTo(second);
}

String findRepositoryNameByType<T>(String? key, NitriteMapper nitriteMapper) {
  return findRepositoryNameByTypeName(getEntityName<T>(nitriteMapper), key);
}

String findRepositoryNameByTypeName(String entityName, String? key) {
  if (key.isNullOrEmpty) {
    return entityName;
  } else {
    return '$entityName$keyObjSeparator$key';
  }
}

String getEntityName<T>(NitriteMapper nitriteMapper) {
  if (isSubtype<T, Entity>()) {
    Entity entity = nitriteMapper.newInstance<T>() as Entity;
    if (!entity.entityName.isNullOrEmpty) {
      return entity.entityName!;
    }
  }
  return T.toString();
}
