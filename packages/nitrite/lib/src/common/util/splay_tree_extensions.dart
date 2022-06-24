import 'dart:collection';

extension SplayTreeMapExtension on SplayTreeMap {
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
}
