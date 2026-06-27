import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/splay_tree_extensions.dart';

import '../common/util/object_utils.dart';

/// @nodoc
class IndexMap {
  final NitriteMap<DBValue, dynamic>? _nitriteMap;
  final SplayTreeMap<dynamic, dynamic>? _navigableMap;

  /// Backing for a non-unique index stored as composite `(value, id)` keys.
  /// When set, this [IndexMap] presents the same `value -> [ids]` view as the
  /// legacy layout, reconstructing each id-list by a prefix range scan.
  final NitriteMap<IndexKey, bool>? _compositeMap;

  bool _reverseScan = false;

  IndexMap(
      {NitriteMap<DBValue, dynamic>? nitriteMap,
      Map<dynamic, dynamic>? subMap,
      NitriteMap<IndexKey, bool>? compositeMap})
      : _nitriteMap = nitriteMap,
        _compositeMap = compositeMap,
        _navigableMap = SplayTreeMapEx.fromMap(subMap);

  set reverseScan(bool reverseScan) {
    _reverseScan = reverseScan;
  }

  DBValue _toDbValue(Comparable? comparable) => comparable is DBNull
      ? comparable
      : (comparable == null ? DBNull.instance : DBValue(comparable));

  Future<dynamic> get(Comparable? comparable) async {
    DBValue dbKey = _toDbValue(comparable);

    if (_compositeMap != null) {
      return _collectIds(dbKey);
    }
    if (_nitriteMap != null) {
      return _nitriteMap[dbKey];
    } else if (_navigableMap != null) {
      return _navigableMap[dbKey];
    }
    return null;
  }

  /// Collects all ids stored for [dbKey] in the composite map by scanning the
  /// `[lowerBound, upperBound]` range for that value.
  Future<List<NitriteId>?> _collectIds(DBValue dbKey) async {
    var ids = <NitriteId>[];
    var key = await _compositeMap!.ceilingKey(IndexKey.lowerBound(dbKey));
    while (key != null && key.value.compareTo(dbKey) == 0) {
      if (key.id != null) ids.add(key.id!);
      key = await _compositeMap.higherKey(key);
    }
    return ids.isEmpty ? null : ids;
  }

  Future<dynamic> firstKey() async {
    if (_compositeMap != null) {
      var k = await _compositeMap.firstKey();
      return _unwrap(k?.value);
    }

    DBValue? dbKey;
    if (_nitriteMap != null) {
      dbKey = await _nitriteMap.firstKey();
    } else if (_navigableMap != null) {
      dbKey = _navigableMap.firstKey();
    } else {
      return null;
    }

    return _unwrap(dbKey);
  }

  Future<dynamic> lastKey() async {
    if (_compositeMap != null) {
      var k = await _compositeMap.lastKey();
      return _unwrap(k?.value);
    }

    DBValue? dbKey;
    if (_nitriteMap != null) {
      dbKey = await _nitriteMap.lastKey();
    } else if (_navigableMap != null) {
      dbKey = _navigableMap.lastKey();
    } else {
      return null;
    }

    return _unwrap(dbKey);
  }

  Future<dynamic> ceilingKey(Comparable? comparable) async {
    DBValue dbKey = _toDbValue(comparable);

    if (_compositeMap != null) {
      // smallest distinct value >= comparable
      var k = await _compositeMap.ceilingKey(IndexKey.lowerBound(dbKey));
      return _unwrap(k?.value);
    }
    if (_nitriteMap != null) {
      return _unwrap(await _nitriteMap.ceilingKey(dbKey));
    } else if (_navigableMap != null) {
      return _unwrap(_navigableMap.ceilingKey(dbKey));
    }
    return null;
  }

  Future<dynamic> higherKey(Comparable? comparable) async {
    DBValue dbKey = _toDbValue(comparable);

    if (_compositeMap != null) {
      // smallest distinct value > comparable
      var k = await _compositeMap.ceilingKey(IndexKey.upperBound(dbKey));
      return _unwrap(k?.value);
    }
    if (_nitriteMap != null) {
      return _unwrap(await _nitriteMap.higherKey(dbKey));
    } else if (_navigableMap != null) {
      return _unwrap(_navigableMap.higherKey(dbKey));
    }
    return null;
  }

  Future<dynamic> floorKey(Comparable? comparable) async {
    DBValue dbKey = _toDbValue(comparable);

    if (_compositeMap != null) {
      // largest distinct value <= comparable
      var k = await _compositeMap.floorKey(IndexKey.upperBound(dbKey));
      return _unwrap(k?.value);
    }
    if (_nitriteMap != null) {
      return _unwrap(await _nitriteMap.floorKey(dbKey));
    } else if (_navigableMap != null) {
      return _unwrap(_navigableMap.floorKey(dbKey));
    }
    return null;
  }

  Future<dynamic> lowerKey(Comparable? comparable) async {
    DBValue dbKey = _toDbValue(comparable);

    if (_compositeMap != null) {
      // largest distinct value < comparable
      var k = await _compositeMap.floorKey(IndexKey.lowerBound(dbKey));
      return _unwrap(k?.value);
    }
    if (_nitriteMap != null) {
      return _unwrap(await _nitriteMap.lowerKey(dbKey));
    } else if (_navigableMap != null) {
      return _unwrap(_navigableMap.lowerKey(dbKey));
    }
    return null;
  }

  dynamic _unwrap(DBValue? dbKey) =>
      dbKey == null || dbKey is DBNull ? null : dbKey.value;

  Stream<(Comparable?, dynamic)> entries() async* {
    if (_compositeMap != null) {
      yield* _compositeEntries();
      return;
    }

    if (_nitriteMap != null) {
      if (!_reverseScan) {
        yield* _nitriteMap.entries().map((entry) {
          var dbKey = entry.$1;
          if (dbKey is DBNull) {
            return (null, entry.$2);
          } else {
            return (dbKey.value, entry.$2);
          }
        });
      } else {
        yield* _nitriteMap.reversedEntries().map((entry) {
          var dbKey = entry.$1;
          if (dbKey is DBNull) {
            return (null, entry.$2);
          } else {
            return (dbKey.value, entry.$2);
          }
        });
      }
    } else if (_navigableMap != null) {
      if (!_reverseScan) {
        yield* Stream.fromIterable(_navigableMap.entries.map((entry) {
          var dbKey = entry.key;
          if (dbKey is DBNull) {
            return (null, entry.value);
          } else {
            return (dbKey.value, entry.value);
          }
        }));
      } else {
        yield* Stream.fromIterable(_navigableMap.reversedEntries.map((entry) {
          var dbKey = entry.key;
          if (dbKey is DBNull) {
            return (null, entry.value);
          } else {
            return (dbKey.value, entry.value);
          }
        }));
      }
    }
    return;
  }

  /// Walks the composite map in order, grouping consecutive entries with the
  /// same value into a `(value, [ids])` pair to match the legacy view.
  Stream<(Comparable?, dynamic)> _compositeEntries() async* {
    var groups = <(DBValue, List<NitriteId>)>[];
    DBValue? current;
    List<NitriteId>? bucket;

    await for (var entry in _compositeMap!.entries()) {
      var key = entry.$1;
      if (current == null || current.compareTo(key.value) != 0) {
        current = key.value;
        bucket = <NitriteId>[];
        groups.add((current, bucket));
      }
      if (key.id != null) bucket!.add(key.id!);
    }

    if (_reverseScan) {
      groups = groups.reversed.toList();
    }

    for (var g in groups) {
      var dbKey = g.$1;
      yield (dbKey is DBNull ? null : dbKey.value, g.$2);
    }
  }

  Stream<NitriteId> getTerminalNitriteIds() async* {
    // scan each entry of the navigable map and collect all terminal nitrite-ids
    await for (var entry in entries()) {
      // if the value is terminal, collect all nitrite-ids
      if (entry.$2 is List) {
        var second = entry.$2 as List;
        var nitriteIds = castList<NitriteId>(second);
        yield* Stream.fromIterable(nitriteIds);
      }

      // if the value is not terminal, scan recursively
      if (entry.$2 is Map) {
        var subMap = entry.$2;
        var indexMap = IndexMap(subMap: subMap);
        yield* indexMap.getTerminalNitriteIds();
      }
    }
  }
}
