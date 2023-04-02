import 'package:collection/collection.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/number_utils.dart' as numbers;
import 'package:nitrite/src/common/util/validation_utils.dart';

bool isSubtype<Subtype, Type>() => <Subtype>[] is List<Type>;

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
    return numbers.compareNum(o1, o2) == 0;
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
    var result = numbers.compareNum(first, second);
    if (first.runtimeType != second.runtimeType) {
      if (result == 0) {
        return first.toString().compareTo(second.toString());
      }
    }
    return result;
  }

  try {
    return first.compareTo(second);
  } on TypeError {
    throw InvalidOperationException(
        'Could not compare type ${first.runtimeType} to ${second.runtimeType}');
  }
}

String findRepositoryNameByType<T>(NitriteMapper nitriteMapper, [String? key]) {
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
  if (isSubtype<T, NitriteEntity>()) {
    NitriteEntity entity = newInstance<T>(nitriteMapper) as NitriteEntity;
    if (!entity.entityName.isNullOrEmpty) {
      return entity.entityName!;
    }
  }
  return T.toString();
}

String findRepositoryNameByDecorator<T>(EntityDecorator<T> entityDecorator,
    [String? key]) {
  var entityName = entityDecorator.entityName;
  if (entityName.contains(keyObjSeparator)) {
    throw ValidationException('$entityName is not a valid entity name');
  }
  return findRepositoryNameByTypeName(entityName, key);
}

T? newInstance<T>(NitriteMapper nitriteMapper) {
  try {
    if (isBuiltInValueType<T>()) {
      return defaultValue<T>();
    }

    return nitriteMapper.convert<T, Document>(Document.emptyDocument());
  } catch (e, s) {
    throw ObjectMappingException("Failed to instantiate type ${T.toString()}",
        cause: e, stackTrace: s);
  }
}

List<Type> builtInTypes() {
  return [
    num,
    int,
    double,
    String,
    Runes,
    bool,
    Null,
    DateTime,
    Duration,
    Symbol
  ];
}

bool isBuiltInValueType<T>() {
  if (isSubtype<T, num>()) return true;
  if (isSubtype<T, num?>()) return true;
  if (isSubtype<T, int>()) return true;
  if (isSubtype<T, int?>()) return true;
  if (isSubtype<T, double>()) return true;
  if (isSubtype<T, double?>()) return true;
  if (isSubtype<T, String>()) return true;
  if (isSubtype<T, String?>()) return true;
  if (isSubtype<T, Runes>()) return true;
  if (isSubtype<T, Runes?>()) return true;
  if (isSubtype<T, bool>()) return true;
  if (isSubtype<T, bool?>()) return true;
  if (isSubtype<T, Null>()) return true;
  if (isSubtype<T, DateTime>()) return true;
  if (isSubtype<T, DateTime?>()) return true;
  if (isSubtype<T, Duration>()) return true;
  if (isSubtype<T, Duration?>()) return true;
  if (isSubtype<T, Symbol>()) return true;
  if (isSubtype<T, Symbol?>()) return true;
  return false;
}

T? defaultValue<T>() {
  if (isSubtype<T, int>()) {
    return 0 as T;
  } else if (isSubtype<T, double>()) {
    return 0.0 as T;
  } else if (isSubtype<T, num>()) {
    return 0 as T;
  } else if (isSubtype<T, bool>()) {
    return false as T;
  } else {
    return null;
  }
}

List<T> castList<T>(List<dynamic> dynamicList) {
  return dynamicList.map((e) => e as T).toList();
}
