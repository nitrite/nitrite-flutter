import 'package:nitrite/nitrite.dart';

/// A class that implements this interface can be used to convert
/// entity into a database {@link Document} and back again.
abstract class EntityConverter<T> {
  /// Gets the entity type.
  Type get entityType => T;

  /// Converts the entity to a [Document].
  Document toDocument(T entity, NitriteMapper nitriteMapper);

  /// Converts a [Document] to an entity of type [T].
  T fromDocument(Document document, NitriteMapper nitriteMapper);

  /// Converts a list of objects of type [L] to a list of [Document]s.
  /// If the type [L] is a registered value type, it will return the
  /// same list without converting its elements.
  static dynamic fromList<L>(List<L>? list, NitriteMapper nitriteMapper) {
    var docList = [];
    if (list != null) {
      for (var item in list) {
        if (item is Iterable) {
          docList.add(fromIterable(item, nitriteMapper));
        } else if (item is Map) {
          docList.add(fromMap(item, nitriteMapper));
        } else {
          docList.add(nitriteMapper.tryConvert<Document, L>(item));
        }
      }
    }
    return docList;
  }

  /// Converts a collection of objects of type [I] to a list of [Document]s.
  /// If the type [I] is a registered value type, it will return the
  /// same list without converting its elements.
  static dynamic fromIterable<I>(
      Iterable<I>? iterable, NitriteMapper nitriteMapper) {
    var docList = [];
    if (iterable != null) {
      for (var item in iterable) {
        if (item is Iterable) {
          docList.add(fromIterable(item, nitriteMapper));
        } else if (item is Map) {
          docList.add(fromMap(item, nitriteMapper));
        } else {
          docList.add(nitriteMapper.tryConvert<Document, I>(item));
        }
      }
    }
    return docList;
  }

  /// Converts a set of objects of type [S] to a set of [Document]s.
  /// If the type [S] is a registered value type, it will return the
  /// same set without converting its elements.
  static dynamic fromSet<S>(Set<S>? set, NitriteMapper nitriteMapper) {
    var docSet = <dynamic>{};
    if (set != null) {
      for (var item in set) {
        if (item is Iterable) {
          docSet.add(fromIterable(item, nitriteMapper));
        } else if (item is Map) {
          docSet.add(fromMap(item, nitriteMapper));
        } else {
          docSet.add(nitriteMapper.tryConvert<Document, S>(item));
        }
      }
    }
    return docSet;
  }

  /// Converts a map of key-value pair to a map of [Document]s.
  /// If the key type [K] or the value type [V] is a registered value type,
  /// it will not convert those objects to document and return as is.
  static dynamic fromMap<K, V>(Map<K, V>? map, NitriteMapper nitriteMapper) {
    var docMap = {};
    if (map != null) {
      for (var entry in map.entries) {
        var key = nitriteMapper.tryConvert<Document, K>(entry.key);
        if (entry.value != null && entry.value is Iterable) {
          var list = fromIterable(entry.value as Iterable, nitriteMapper);
          docMap[key] = list;
        } else if (entry.value != null && entry.value is Map) {
          var map = fromMap(entry.value as Map, nitriteMapper);
          docMap[key] = map;
        } else {
          var value = nitriteMapper.tryConvert<Document, V>(entry.value);
          docMap[key] = value;
        }
      }
    }
    return docMap;
  }

  /// Converts a list of [Document]s to a list of object type [L].
  static List<L> toList<L>(dynamic list, NitriteMapper nitriteMapper) {
    var resultList = <L>[];
    if (list is Iterable && list is! Document) {
      for (var item in list) {
        if (item is Iterable && list is! Document) {
          var list = toList<L>(item, nitriteMapper);
          resultList.addAll(list);
        }
        if (item is Map) {
          var map = toMap(item, nitriteMapper);
          resultList.add(map as L);
        } else {
          var element = nitriteMapper.tryConvert<L, dynamic>(item);
          if (element != null) {
            resultList.add(element);
          }
        }
      }
    }
    return resultList;
  }

  /// Converts a collection of [Document]s to a list of object type [I].
  static Iterable<I> toIterable<I>(dynamic list, NitriteMapper nitriteMapper) {
    var resultList = <I>[];
    if (list is Iterable && list is! Document) {
      for (var item in list) {
        if (item is Iterable && item is! Document) {
          var list = toList<I>(item, nitriteMapper);
          resultList.addAll(list);
        }
        if (item is Map) {
          var map = toMap(item, nitriteMapper);
          resultList.add(map as I);
        } else {
          var element = nitriteMapper.tryConvert<I, dynamic>(item);
          if (element != null) {
            resultList.add(element);
          }
        }
      }
    }
    return resultList;
  }

  /// Converts a set of [Document]s to a set of object type [S].
  static Set<S> toSet<S>(dynamic set, NitriteMapper nitriteMapper) {
    var resultSet = <S>{};
    if (set is Iterable && set is! Document) {
      for (var item in set) {
        if (item is Iterable && item is! Document) {
          var list = toList<S>(item, nitriteMapper);
          resultSet.addAll(list);
        }
        if (item is Map) {
          var map = toMap(item, nitriteMapper);
          resultSet.add(map as S);
        } else {
          var element = nitriteMapper.tryConvert<S, dynamic>(item);
          if (element != null) {
            resultSet.add(element);
          }
        }
      }
    }
    return resultSet;
  }

  /// Converts a map of [Document]s to a map of key value pair.
  static Map<K, V> toMap<K, V>(dynamic map, NitriteMapper nitriteMapper) {
    var resultMap = <K, V>{};
    if (map is Map) {
      for (var item in map.entries) {
        var key = nitriteMapper.tryConvert<K, dynamic>(item.key);
        var v = item.value;

        if (v is Iterable && v is! Document) {
          var value = toList(v, nitriteMapper);
          resultMap[key] = value as V;
        } else if (v is Map) {
          var map = toMap(v, nitriteMapper);
          resultMap[key] = map as V;
        } else {
          var value = nitriteMapper.tryConvert<V, dynamic>(item.value);
          if (key != null) {
            resultMap[key] = value as V;
          }
        }
      }
    }
    return resultMap;
  }
}
