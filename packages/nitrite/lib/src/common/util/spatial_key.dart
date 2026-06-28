import 'dart:math' as math;

import 'package:collection/collection.dart';

/// Returns the ids of the [k] spatial keys nearest to the point ([x], [y]),
/// ordered by ascending distance to each key's bounding box. Keys with an empty
/// bounding box are skipped; if [maxDistance] is given, keys farther than it are
/// excluded.
///
/// @nodoc
Iterable<int> nearestNeighborIds(
  Iterable<SpatialKey> keys,
  double x,
  double y,
  int k, [
  double? maxDistance,
]) {
  var scored = <(int, double)>[];
  for (var sk in keys) {
    if (sk.isNull()) continue;
    var d = sk.distanceToPoint(x, y);
    if (maxDistance != null && d > maxDistance) continue;
    scored.add((sk.id, d));
  }
  scored.sort((a, b) => a.$2.compareTo(b.$2));
  return scored.take(k).map((e) => e.$1);
}

/// @nodoc
class SpatialKey {
  final int id;
  final List<double> minMax;

  SpatialKey(this.id, this.minMax);

  double min(int dim) {
    return minMax[dim + dim];
  }

  void setMin(int dim, double value) {
    minMax[dim + dim] = value;
  }

  double max(int dim) {
    return minMax[dim + dim + 1];
  }

  void setMax(int dim, double value) {
    minMax[dim + dim + 1] = value;
  }

  bool isNull() {
    return minMax.isEmpty;
  }

  /// The Euclidean distance from the point ([x], [y]) to this key's bounding
  /// box. Zero if the point lies inside the box.
  double distanceToPoint(double x, double y) {
    var dx = math.max(math.max(min(0) - x, x - max(0)), 0.0);
    var dy = math.max(math.max(min(1) - y, y - max(1)), 0.0);
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  int get hashCode => (id >>> 32) ^ id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    } else if (other is! SpatialKey) {
      return false;
    }

    if (id != other.id) {
      return false;
    }

    return ListEquality().equals(minMax, other.minMax);
  }

  @override
  String toString() {
    return 'SpatialKey{id: $id, minMax: $minMax}';
  }
}
