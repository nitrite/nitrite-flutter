import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/splay_tree_extensions.dart';

import '../common/util/object_utils.dart';

/// @nodoc
class IndexMap {
  final NitriteMap<DBValue, dynamic>? _nitriteMap;
  final SplayTreeMap<dynamic, dynamic>? _navigableMap;

  /// Backing for a non-unique index stored as composite `(values…, id)` keys.
  /// When set, this [IndexMap] presents the same view as the legacy layout
  /// (single field: `value -> [ids]`; compound: `value -> nested sub-map`),
  /// reconstructing it by a prefix range scan on the first field's value.
  final NitriteMap<IndexKey, bool>? _compositeMap;

  /// Number of indexed fields for [_compositeMap]: 1 means each first-field
  /// value maps to a terminal id-list, >1 means a nested sub-map.
  final int _compositeFieldCount;

  bool _reverseScan = false;

  IndexMap({
    NitriteMap<DBValue, dynamic>? nitriteMap,
    Map<dynamic, dynamic>? subMap,
    NitriteMap<IndexKey, bool>? compositeMap,
    int compositeFieldCount = 1,
  })  : _nitriteMap = nitriteMap,
        _compositeMap = compositeMap,
        _compositeFieldCount = compositeFieldCount,
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
      var keys = await _collectKeys(dbKey);
      if (keys.isEmpty) return null;
      return _compositeFieldCount == 1
          ? [for (var k in keys) k.id!]
          : _buildNested(keys);
    }
    if (_nitriteMap != null) {
      return _nitriteMap[dbKey];
    } else if (_navigableMap != null) {
      return _navigableMap[dbKey];
    }
    return null;
  }

  /// Collects every composite entry whose first-field value equals [dbKey] by
  /// scanning the `[lowerBound, upperBound]` range for that value.
  Future<List<IndexKey>> _collectKeys(DBValue dbKey) async {
    var result = <IndexKey>[];
    var key = await _compositeMap!.ceilingKey(IndexKey.lowerBound([dbKey]));
    while (key != null && key.value.compareTo(dbKey) == 0) {
      result.add(key);
      key = await _compositeMap.higherKey(key);
    }
    return result;
  }

  /// Rebuilds the legacy nested sub-map (keyed by the 2nd..last field values,
  /// terminal id-lists) for a group of compound entries sharing a first value.
  Map<DBValue, dynamic> _buildNested(List<IndexKey> keys) {
    var root = <DBValue, dynamic>{};
    for (var key in keys) {
      var vals = key.values;
      Map node = root;
      for (var i = 1; i < vals.length - 1; i++) {
        node = (node[vals[i]] ??= <DBValue, dynamic>{}) as Map;
      }
      var terminal = vals[vals.length - 1];
      var list = (node[terminal] ??= <NitriteId>[]) as List;
      list.add(key.id!);
    }
    return root;
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
      var k = await _compositeMap.ceilingKey(IndexKey.lowerBound([dbKey]));
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
      var k = await _compositeMap.ceilingKey(IndexKey.upperBound([dbKey]));
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
      var k = await _compositeMap.floorKey(IndexKey.upperBound([dbKey]));
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
      var k = await _compositeMap.floorKey(IndexKey.lowerBound([dbKey]));
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
        yield* Stream.fromIterable(
          _navigableMap.entries.map((entry) {
            var dbKey = entry.key;
            if (dbKey is DBNull) {
              return (null, entry.value);
            } else {
              return (dbKey.value, entry.value);
            }
          }),
        );
      } else {
        yield* Stream.fromIterable(
          _navigableMap.reversedEntries.map((entry) {
            var dbKey = entry.key;
            if (dbKey is DBNull) {
              return (null, entry.value);
            } else {
              return (dbKey.value, entry.value);
            }
          }),
        );
      }
    }
    return;
  }

  /// Walks the composite map in order, grouping consecutive entries with the
  /// same first-field value into a `(value, idsOrSubMap)` pair to match the
  /// legacy view (id-list for single field, nested sub-map for compound).
  Stream<(Comparable?, dynamic)> _compositeEntries() async* {
    var groups = <(DBValue, List<IndexKey>)>[];
    DBValue? current;
    List<IndexKey>? bucket;

    await for (var entry in _compositeMap!.entries()) {
      var key = entry.$1;
      if (current == null || current.compareTo(key.value) != 0) {
        current = key.value;
        bucket = <IndexKey>[];
        groups.add((current, bucket));
      }
      bucket!.add(key);
    }

    if (_reverseScan) {
      groups = groups.reversed.toList();
    }

    for (var g in groups) {
      var dbKey = g.$1;
      var value = _compositeFieldCount == 1
          ? [for (var k in g.$2) k.id!]
          : _buildNested(g.$2);
      yield (dbKey is DBNull ? null : dbKey.value, value);
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
