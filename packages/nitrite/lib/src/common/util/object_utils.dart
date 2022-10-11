import 'package:collection/collection.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/number_utils.dart' as numbers;
import 'package:nitrite/src/common/util/validation_utils.dart';

void blackHole(dynamic _) {}

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
      if (result == 0) return 1;
    }
    return result;
  }
  return first.compareTo(second);
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
    if (builtInTypes().contains(T)) {
      return _defaultValue<T>();
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

bool isValue<T>(T value, NitriteMapper nitriteMapper) {
  try {
    if (value == null) return true;

    // if it is registered with nitrite mapper as value
    // then no exception will be thrown
    nitriteMapper.convert<Comparable, T>(value);
    return true;
  } catch (e) {
    return isBuiltInValueType<T>();
  }
}

bool isValueType<T>(NitriteMapper nitriteMapper) {
  try {
    var value = newInstance<T>(nitriteMapper);
    if (value != null) {
      return isValue(value, nitriteMapper);
    } else {
      return isBuiltInValueType<T>();
    }
  } catch (e) {
    return isBuiltInValueType<T>();
  }
}

bool isBuiltInValueType<T>() {
  if (isSubtype<T, num>()) return true;
  if (isSubtype<T, List>()) return true;
  if (isSubtype<T, Set>()) return true;
  if (isSubtype<T, Map>()) return true;
  if (isSubtype<T, Symbol>()) return true;
  return (builtInTypes().contains(T));
}

T? _defaultValue<T>() {
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
