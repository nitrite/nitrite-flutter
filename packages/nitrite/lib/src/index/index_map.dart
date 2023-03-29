import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/splay_tree_extensions.dart';

class IndexMap {
  final NitriteMap<DBValue, dynamic>? _nitriteMap;
  final SplayTreeMap<dynamic, dynamic>? _navigableMap;
  bool _reverseScan = false;

  IndexMap(
      {NitriteMap<DBValue, dynamic>? nitriteMap,
      SplayTreeMap<dynamic, dynamic>? navigableMap})
      : _nitriteMap = nitriteMap,
        _navigableMap = navigableMap;

  set reverseScan(bool reverseScan) {
    _reverseScan = reverseScan;
  }

  Future<dynamic> get(Comparable? comparable) async {
    DBValue? dbKey = comparable is DBNull
        ? comparable
        : (comparable == null ? DBNull.instance : DBValue(comparable));

    if (_nitriteMap != null) {
      return _nitriteMap![dbKey];
    } else if (_navigableMap != null) {
      return _navigableMap![dbKey];
    }
    return null;
  }

  Future<dynamic> ceilingKey(Comparable? comparable) async {
    DBValue? dbKey = comparable is DBNull
        ? comparable
        : (comparable == null ? DBNull.instance : DBValue(comparable));

    if (!_reverseScan) {
      if (_nitriteMap != null) {
        dbKey = await _nitriteMap!.ceilingKey(dbKey);
      } else if (_navigableMap != null) {
        dbKey = _navigableMap!.ceilingKey(dbKey);
      }
    } else {
      if (_nitriteMap != null) {
        dbKey = await _nitriteMap!.floorKey(dbKey);
      } else if (_navigableMap != null) {
        dbKey = _navigableMap!.floorKey(dbKey);
      }
    }

    return dbKey == null || dbKey == DBNull.instance ? null : dbKey.value;
  }

  Future<dynamic> higherKey(Comparable? comparable) async {
    DBValue? dbKey = comparable is DBNull
        ? comparable
        : (comparable == null ? DBNull.instance : DBValue(comparable));

    if (!_reverseScan) {
      if (_nitriteMap != null) {
        dbKey = await _nitriteMap!.higherKey(dbKey);
      } else if (_navigableMap != null) {
        dbKey = _navigableMap!.higherKey(dbKey);
      }
    } else {
      if (_nitriteMap != null) {
        dbKey = await _nitriteMap!.lowerKey(dbKey);
      } else if (_navigableMap != null) {
        dbKey = _navigableMap!.lowerKey(dbKey);
      }
    }

    return dbKey == null || dbKey == DBNull.instance ? null : dbKey.value;
  }

  Future<dynamic> floorKey(Comparable? comparable) async {
    DBValue? dbKey = comparable is DBNull
        ? comparable
        : (comparable == null ? DBNull.instance : DBValue(comparable));

    if (!_reverseScan) {
      if (_nitriteMap != null) {
        dbKey = await _nitriteMap!.floorKey(dbKey);
      } else if (_navigableMap != null) {
        dbKey = _navigableMap!.floorKey(dbKey);
      }
    } else {
      if (_nitriteMap != null) {
        dbKey = await _nitriteMap!.ceilingKey(dbKey);
      } else if (_navigableMap != null) {
        dbKey = _navigableMap!.ceilingKey(dbKey);
      }
    }

    return dbKey == null || dbKey == DBNull.instance ? null : dbKey.value;
  }

  Future<dynamic> lowerKey(Comparable? comparable) async {
    DBValue? dbKey = comparable is DBNull
        ? comparable
        : (comparable == null ? DBNull.instance : DBValue(comparable));

    if (!_reverseScan) {
      if (_nitriteMap != null) {
        dbKey = await _nitriteMap!.lowerKey(dbKey);
      } else if (_navigableMap != null) {
        dbKey = _navigableMap!.lowerKey(dbKey);
      }
    } else {
      if (_nitriteMap != null) {
        dbKey = await _nitriteMap!.higherKey(dbKey);
      } else if (_navigableMap != null) {
        dbKey = _navigableMap!.higherKey(dbKey);
      }
    }

    return dbKey == null || dbKey is DBNull ? null : dbKey.value;
  }

  Stream<Pair<Comparable?, dynamic>> entries() async* {
    if (_nitriteMap != null) {
      if (!_reverseScan) {
        yield* _nitriteMap!.entries().map((entry) {
          var dbKey = entry.first;
          if (dbKey is DBNull) {
            return Pair(null, entry.second);
          } else {
            return Pair(dbKey.value, entry.second);
          }
        });
      } else {
        yield* _nitriteMap!.reversedEntries().map((entry) {
          var dbKey = entry.first;
          if (dbKey is DBNull) {
            return Pair(null, entry.second);
          } else {
            return Pair(dbKey.value, entry.second);
          }
        });
      }
    } else if (_navigableMap != null) {
      if (!_reverseScan) {
        yield* Stream.fromIterable(_navigableMap!.entries.map((entry) {
          var dbKey = entry.key;
          if (dbKey is DBNull) {
            return Pair(null, entry.value);
          } else {
            return Pair(dbKey.value, entry.value);
          }
        }));
      } else {
        yield* Stream.fromIterable(_navigableMap!.reversedEntries.map((entry) {
          var dbKey = entry.key;
          if (dbKey is DBNull) {
            return Pair(null, entry.value);
          } else {
            return Pair(dbKey.value, entry.value);
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
      if (entry.second is List) {
        var nitriteIds = entry.second as List<NitriteId>;
        yield* Stream.fromIterable(nitriteIds);
      }

      // if the value is not terminal, scan recursively
      if (entry.second is Map) {
        var subMap = SplayTreeMapExtension.fromMap(entry.second)
            as SplayTreeMap<DBValue, dynamic>;
        var indexMap = IndexMap(navigableMap: subMap);
        yield* indexMap.getTerminalNitriteIds();
      }
    }
  }
}
