import 'package:collection/collection.dart';

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
