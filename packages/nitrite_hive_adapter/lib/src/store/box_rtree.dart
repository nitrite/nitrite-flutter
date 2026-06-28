import 'package:nitrite/nitrite.dart';

import 'box_map.dart';

/// @nodoc
class BoxRTree<Key extends BoundingBox, Value>
    extends NitriteRTree<Key, Value> {
  final BoxMap<SpatialKey, Key?> _backingMap;

  /// In-memory spatial index over the durable [_backingMap] keys, giving
  /// O(log n + result) queries instead of a full key scan. Hydrated lazily from
  /// the box on first query and kept in sync on subsequent writes.
  final SpatialRTree _tree = SpatialRTree();
  bool _loaded = false;
  bool _dropped = false;
  bool _closed = false;

  BoxRTree(this._backingMap);

  @override
  Future<void> add(Key? key, NitriteId? value) async {
    _checkOpened();
    if (value != null) {
      var spatialKey = _getKey(key, int.parse(value.idValue));
      await _backingMap.put(spatialKey, key);
      if (_loaded) _tree.put(spatialKey);
    }
  }

  @override
  Future<void> clear() async {
    _checkOpened();
    await _backingMap.clear();
    _tree.clear();
    _loaded = true;
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
    await _ensureLoaded();
    var query = _getKey(key, 0);
    for (var id in _tree.contained(query)) {
      yield NitriteId.createId(id.toString());
    }
  }

  @override
  Stream<NitriteId> findIntersectingKeys(Key? key) async* {
    _checkOpened();
    await _ensureLoaded();
    var query = _getKey(key, 0);
    for (var id in _tree.intersecting(query)) {
      yield NitriteId.createId(id.toString());
    }
  }

  @override
  Stream<NitriteId> findNearestNeighbors(double x, double y, int k,
      [double? maxDistance]) async* {
    _checkOpened();
    await _ensureLoaded();
    for (var id in _tree.nearest(x, y, k, maxDistance)) {
      yield NitriteId.createId(id.toString());
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
      if (_loaded) _tree.removeId(spatialKey.id);
    }
  }

  @override
  Future<int> size() async {
    _checkOpened();
    return _backingMap.size();
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    await for (var sk in _backingMap.keys()) {
      _tree.put(sk);
    }
    _loaded = true;
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
}
