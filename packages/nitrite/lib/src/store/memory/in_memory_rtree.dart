import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:nitrite/nitrite.dart';

class InMemoryRTree<Key extends BoundingBox, Value>
    extends NitriteRTree<Key, Value> {
  final Map<_SpatialKey, Key> _backingMap =
      SplayTreeMap<_SpatialKey, Key>();

  bool _droppedFlag = false;
  bool _closedFlag = false;

  @override
  Future<int> get size async {
    _checkOpened();
    return _backingMap.length;
  }

  @override
  Future<void> add(Key key, NitriteId? value) async {
    _checkOpened();
    if (value != null) {
      var spatialKey = _getKey(key, int.parse(value.idValue));
      _backingMap[spatialKey] = key;
    }
  }

  @override
  Future<void> remove(Key key, NitriteId? value) async {
    _checkOpened();
    if (value != null) {
      var spatialKey = _getKey(key, int.parse(value.idValue));
      _backingMap.remove(spatialKey);
    }
  }

  @override
  Stream<NitriteId> findIntersectingKeys(Key key) async* {
    _checkOpened();
    var spatialKey = _getKey(key, 0);

    for(var sk in _backingMap.keys) {
      if (_isOverlap(sk, spatialKey)) {
        yield NitriteId.createId(sk.id.toString());
      }
    }
  }

  @override
  Stream<NitriteId> findContainedKeys(Key key) async* {
    _checkOpened();
    var spatialKey = _getKey(key, 0);

    for(var sk in _backingMap.keys) {
      if (_isInside(sk, spatialKey)) {
        yield NitriteId.createId(sk.id.toString());
      }
    }
  }

  @override
  Future<void> clear() async {
    _checkOpened();
    _backingMap.clear();
  }

  @override
  Future<void> close() async {
    _closedFlag = true;
  }

  @override
  Future<void> drop() async {
    _checkOpened();
    _droppedFlag = true;
    _backingMap.clear();
  }

  _SpatialKey _getKey(Key key, int id) {
    return _SpatialKey(id, [key.minX, key.maxX, key.minY, key.maxY]);
  }

  bool _isOverlap(_SpatialKey a, _SpatialKey b) {
    for (var i = 0; i < 2; i++) {
      if (a.max(i) < b.min(i) || a.min(i) > b.max(i)) {
        return false;
      }
    }
    return true;
  }

  bool _isInside(_SpatialKey a, _SpatialKey b) {
    for (var i = 0; i < 2; i++) {
      if (a.min(i) <= b.min(i) || a.max(i) >= b.max(i)) {
        return false;
      }
    }
    return true;
  }

  void _checkOpened() {
    if (_closedFlag) {
      throw NitriteException('RTreeMap is closed');
    }
    if (_droppedFlag) {
      throw NitriteException('RTreeMap is dropped');
    }
  }
}

class _SpatialKey {
  final int id;
  final List<double> minMax;

  const _SpatialKey(this.id, this.minMax);

  double min(int dim) {
    return minMax[dim * 2];
  }

  void setMin(int dim, double value) {
    minMax[dim * 2] = value;
  }

  double max(int dim) {
    return minMax[dim * 2 + 1];
  }

  void setMax(int dim, double value) {
    minMax[dim * 2 + 1] = value;
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
    } else if (other is! _SpatialKey) {
      return false;
    }

    if (id != other.id) {
      return false;
    }

    return ListEquality().equals(minMax, other.minMax);
  }
}
