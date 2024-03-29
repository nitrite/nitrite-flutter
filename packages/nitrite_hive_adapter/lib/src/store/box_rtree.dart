import 'package:nitrite/nitrite.dart';

import 'box_map.dart';

/// @nodoc
class BoxRTree<Key extends BoundingBox, Value>
    extends NitriteRTree<Key, Value> {
  final BoxMap<SpatialKey, Key?> _backingMap;
  bool _dropped = false;
  bool _closed = false;

  BoxRTree(this._backingMap);

  @override
  Future<void> add(Key? key, NitriteId? value) async {
    _checkOpened();
    if (value != null) {
      var spatialKey = _getKey(key, int.parse(value.idValue));
      await _backingMap.put(spatialKey, key);
    }
  }

  @override
  Future<void> clear() async {
    _checkOpened();
    await _backingMap.clear();
  }

  @override
  Future<void> close() async {
    _checkOpened();
    _closed = true;
    await _backingMap.close();
  }

  @override
  Future<void> drop() async {
    _checkOpened();
    _dropped = true;
    await _backingMap.drop();
  }

  @override
  Stream<NitriteId> findContainedKeys(Key? key) async* {
    _checkOpened();
    var spatialKey = _getKey(key, 0);

    await for (var sk in _backingMap.keys()) {
      if (_isInside(sk, spatialKey)) {
        yield NitriteId.createId(sk.id.toString());
      }
    }
  }

  @override
  Stream<NitriteId> findIntersectingKeys(Key? key) async* {
    _checkOpened();
    var spatialKey = _getKey(key, 0);

    await for (var sk in _backingMap.keys()) {
      if (_isOverlap(sk, spatialKey)) {
        yield NitriteId.createId(sk.id.toString());
      }
    }
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> remove(Key? key, NitriteId? value) async {
    _checkOpened();
    if (value != null) {
      var spatialKey = _getKey(key, int.parse(value.idValue));
      await _backingMap.remove(spatialKey);
    }
  }

  @override
  Future<int> size() async {
    _checkOpened();
    return _backingMap.size();
  }

  void _checkOpened() {
    if (_closed) throw InvalidOperationException('RTreeMap is closed');
    if (_dropped) throw InvalidOperationException('RTreeMap is dropped');
  }

  SpatialKey _getKey(Key? key, int id) {
    if (key == null || key == BoundingBox.empty) {
      return SpatialKey(id, []);
    }
    return SpatialKey(id, [key.minX, key.maxX, key.minY, key.maxY]);
  }

  bool _isOverlap(SpatialKey a, SpatialKey b) {
    if (a.isNull() || b.isNull()) {
      return false;
    }

    for (var i = 0; i < 2; i++) {
      if (a.max(i) < b.min(i) || a.min(i) > b.max(i)) {
        return false;
      }
    }

    return true;
  }

  bool _isInside(SpatialKey a, SpatialKey b) {
    if (a.isNull() || b.isNull()) {
      return false;
    }

    for (var i = 0; i < 2; i++) {
      if (a.min(i) <= b.min(i) || a.max(i) >= b.max(i)) {
        return false;
      }
    }

    return true;
  }
}
