import 'dart:collection';

import 'package:nitrite/nitrite.dart';

class InMemoryRTree<Key extends BoundingBox, Value>
    extends NitriteRTree<Key, Value> {
  final Map<SpatialKey, Key> _backingMap = SplayTreeMap<SpatialKey, Key>();
  final NitriteStore _nitriteStore;
  final String _mapName;

  bool _droppedFlag = false;
  bool _closedFlag = false;

  InMemoryRTree(this._mapName, this._nitriteStore);

  @override
  Future<int> size() async {
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

    for (var sk in _backingMap.keys) {
      if (_isOverlap(sk, spatialKey)) {
        yield NitriteId.createId(sk.id.toString());
      }
    }
  }

  @override
  Stream<NitriteId> findContainedKeys(Key key) async* {
    _checkOpened();
    var spatialKey = _getKey(key, 0);

    for (var sk in _backingMap.keys) {
      if (_isInside(sk, spatialKey)) {
        yield NitriteId.createId(sk.id.toString());
      }
    }
  }

  @override
  Future<void> clear() async {
    _checkOpened();
    _backingMap.clear();
    await _nitriteStore.closeRTree(_mapName);
  }

  @override
  Future<void> close() async {
    _closedFlag = true;
    await _nitriteStore.closeRTree(_mapName);
  }

  @override
  Future<void> drop() async {
    _checkOpened();
    _droppedFlag = true;
    _backingMap.clear();
    await _nitriteStore.removeRTree(_mapName);
  }

  SpatialKey _getKey(Key key, int id) {
    return SpatialKey(id, [key.minX, key.maxX, key.minY, key.maxY]);
  }

  bool _isOverlap(SpatialKey a, SpatialKey b) {
    for (var i = 0; i < 2; i++) {
      if (a.max(i) < b.min(i) || a.min(i) > b.max(i)) {
        return false;
      }
    }
    return true;
  }

  bool _isInside(SpatialKey a, SpatialKey b) {
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

  @override
  Future<void> initialize() async {}
}
