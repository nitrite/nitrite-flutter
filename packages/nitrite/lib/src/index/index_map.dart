import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/splay_tree_extensions.dart';

import '../common/util/object_utils.dart';

/// @nodoc
class IndexMap {
  final NitriteMap<DBValue, dynamic>? _nitriteMap;
  final SplayTreeMap<dynamic, dynamic>? _navigableMap;
  bool _reverseScan = false;

  IndexMap(
      {NitriteMap<DBValue, dynamic>? nitriteMap, Map<dynamic, dynamic>? subMap})
      : _nitriteMap = nitriteMap,
        _navigableMap = SplayTreeMapEx.fromMap(subMap);

  set reverseScan(bool reverseScan) {
    _reverseScan = reverseScan;
  }

  Future<dynamic> get(Comparable? comparable) async {
    DBValue? dbKey = comparable is DBNull
        ? comparable
        : (comparable == null ? DBNull.instance : DBValue(comparable));

    if (_nitriteMap != null) {
      return _nitriteMap[dbKey];
    } else if (_navigableMap != null) {
      return _navigableMap[dbKey];
    }
    return null;
  }

  Future<dynamic> firstKey() async {
    DBValue? dbKey;
    if (_nitriteMap != null) {
      dbKey = await _nitriteMap.firstKey();
    } else if (_navigableMap != null) {
      dbKey = _navigableMap.firstKey();
    } else {
      return null;
    }

    return dbKey == null || dbKey == DBNull.instance ? null : dbKey.value;
  }

  Future<dynamic> lastKey() async {
    DBValue? dbKey;
    if (_nitriteMap != null) {
      dbKey = await _nitriteMap.lastKey();
    } else if (_navigableMap != null) {
      dbKey = _navigableMap.lastKey();
    } else {
      return null;
    }

    return dbKey == null || dbKey == DBNull.instance ? null : dbKey.value;
  }

  Future<dynamic> ceilingKey(Comparable? comparable) async {
    DBValue? dbKey = comparable is DBNull
        ? comparable
        : (comparable == null ? DBNull.instance : DBValue(comparable));

    if (_nitriteMap != null) {
      dbKey = await _nitriteMap.ceilingKey(dbKey);
    } else if (_navigableMap != null) {
      dbKey = _navigableMap.ceilingKey(dbKey);
    }

    return dbKey == null || dbKey == DBNull.instance ? null : dbKey.value;
  }

  Future<dynamic> higherKey(Comparable? comparable) async {
    DBValue? dbKey = comparable is DBNull
        ? comparable
        : (comparable == null ? DBNull.instance : DBValue(comparable));

    if (_nitriteMap != null) {
      dbKey = await _nitriteMap.higherKey(dbKey);
    } else if (_navigableMap != null) {
      dbKey = _navigableMap.higherKey(dbKey);
    }

    return dbKey == null || dbKey == DBNull.instance ? null : dbKey.value;
  }

  Future<dynamic> floorKey(Comparable? comparable) async {
    DBValue? dbKey = comparable is DBNull
        ? comparable
        : (comparable == null ? DBNull.instance : DBValue(comparable));

    if (_nitriteMap != null) {
      dbKey = await _nitriteMap.floorKey(dbKey);
    } else if (_navigableMap != null) {
      dbKey = _navigableMap.floorKey(dbKey);
    }

    return dbKey == null || dbKey == DBNull.instance ? null : dbKey.value;
  }

  Future<dynamic> lowerKey(Comparable? comparable) async {
    DBValue? dbKey = comparable is DBNull
        ? comparable
        : (comparable == null ? DBNull.instance : DBValue(comparable));

    if (_nitriteMap != null) {
      dbKey = await _nitriteMap.lowerKey(dbKey);
    } else if (_navigableMap != null) {
      dbKey = _navigableMap.lowerKey(dbKey);
    }

    return dbKey == null || dbKey is DBNull ? null : dbKey.value;
  }

  Stream<(Comparable?, dynamic)> entries() async* {
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
