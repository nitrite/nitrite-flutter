import 'package:hive/hive.dart';

/// @nodoc
extension BoxExtension on Box {
  dynamic higherKey(dynamic key) {
    return _getMinMax(key, false, true);
  }

  dynamic ceilingKey(dynamic key) {
    return _getMinMax(key, false, false);
  }

  dynamic lowerKey(dynamic key) {
    return _getMinMax(key, true, true);
  }

  dynamic floorKey(dynamic key) {
    return _getMinMax(key, true, false);
  }

  dynamic _getMinMax(dynamic key, bool min, bool excluding) {
    int x = _binarySearch(key);
    if (x < 0) {
      x = -x - (min ? 2 : 1);
    } else if (excluding) {
      x += min ? -1 : 1;
    }

    if (x < 0 || x >= length) {
      return null;
    }
    return keyAt(x);
  }

  int _binarySearch(dynamic key) {
    int low = 0, high = length - 1;
    int cachedCompare = 0;
    int x = cachedCompare - 1;
    if (x < 0 || x > high) {
      x = high >>> 1;
    }

    while (low <= high) {
      int compare = Comparable.compare(key, keyAt(x));
      if (compare > 0) {
        low = x + 1;
      } else if (compare < 0) {
        high = x - 1;
      } else {
        cachedCompare = x + 1;
        return x;
      }
      x = (low + high) >>> 1;
    }

    cachedCompare = low;
    return -(low + 1);
  }
}
