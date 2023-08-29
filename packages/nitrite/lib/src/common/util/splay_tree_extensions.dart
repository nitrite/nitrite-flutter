import 'dart:collection';

/// @nodoc
extension SplayTreeMapEx on SplayTreeMap {
  static SplayTreeMap? fromMap(Map? map) {
    if (map == null) return null;
    var stm = SplayTreeMap();
    for (var entry in map.entries) {
      stm[entry.key] = entry.value;
    }
    return stm;
  }

  dynamic higherKey(dynamic key) {
    return firstKeyAfter(key);
  }

  dynamic ceilingKey(dynamic key) {
    if (containsKey(key)) return key;
    return firstKeyAfter(key);
  }

  dynamic lowerKey(dynamic key) {
    return lastKeyBefore(key);
  }

  dynamic floorKey(dynamic key) {
    if (containsKey(key)) return key;
    return lastKeyBefore(key);
  }

  Iterable<MapEntry> get reversedEntries {
    return entries.toList().reversed;
  }

  Map toMap() {
    var map = <dynamic, dynamic>{};
    for (var entry in entries) {
      map[entry.key] = entry.value;
    }
    return map;
  }
}
