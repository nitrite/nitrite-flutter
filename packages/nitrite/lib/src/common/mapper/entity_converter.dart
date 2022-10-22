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

  dynamic fromList<L>(List<L>? list, NitriteMapper nitriteMapper) {
    var docList = [];
    if (list != null) {
      for (var item in list) {
        docList.add(nitriteMapper.convert<Document, L>(item));
      }
    }
    return docList;
  }

  dynamic fromIterable<I>(Iterable<I>? iterable, NitriteMapper nitriteMapper) {
    var docList = [];
    if (iterable != null) {
      for (var item in iterable) {
        docList.add(nitriteMapper.convert<Document, I>(item));
      }
    }
    return docList;
  }

  dynamic fromSet<S>(Set<S>? set, NitriteMapper nitriteMapper) {
    var docSet = <dynamic>{};
    if (set != null) {
      for (var item in set) {
        docSet.add(nitriteMapper.convert<Document, S>(item));
      }
    }
    return docSet;
  }

  dynamic fromMap<K, V>(Map<K, V>? map, NitriteMapper nitriteMapper) {
    var docMap = {};
    if (map != null) {
      for (var entry in map.entries) {
        var key = nitriteMapper.convert<Document, K>(entry.key);
        var value = nitriteMapper.convert<Document, V>(entry.value);
        docMap[key] = value;
      }
    }
    return docMap;
  }

  List<L> toList<L>(dynamic list, NitriteMapper nitriteMapper) {
    var resultList = <L>[];
    if (list is List) {
      for (var item in list) {
        var element = nitriteMapper.convert<L, Document>(item);
        if (element != null) {
          resultList.add(element);
        }
      }
    }
    return resultList;
  }

  Iterable<I> toIterable<I>(dynamic list, NitriteMapper nitriteMapper) {
    var resultList = <I>[];
    if (list is Iterable) {
      for (var item in list) {
        var element = nitriteMapper.convert<I, Document>(item);
        if (element != null) {
          resultList.add(element);
        }
      }
    }
    return resultList;
  }

  Set<S> toSet<S>(dynamic set, NitriteMapper nitriteMapper) {
    var resultSet = <S>{};
    if (set is Set) {
      for (var item in set) {
        var element = nitriteMapper.convert<S, Document>(item);
        if (element != null) {
          resultSet.add(element);
        }
      }
    }
    return resultSet;
  }

  Map<K, V> toMap<K, V>(dynamic map, NitriteMapper nitriteMapper) {
    var resultMap = <K, V>{};
    if (map is Map) {
      for (var item in map.entries) {
        var key = nitriteMapper.convert<K, Document>(item.key);
        var value = nitriteMapper.convert<V, Document>(item.value);
        if (key != null) {
          resultMap[key] = value as V;
        }
      }
    }
    return resultMap;
  }
}
