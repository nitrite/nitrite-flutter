import 'package:nitrite/nitrite.dart';

/// @nodoc
class InMemoryRTree<Key extends BoundingBox, Value>
    extends NitriteRTree<Key, Value> {
  final SpatialRTree _tree = SpatialRTree();
  final NitriteStore _nitriteStore;
  final String _mapName;

  bool _droppedFlag = false;
  bool _closedFlag = false;

  InMemoryRTree(this._mapName, this._nitriteStore);

  @override
  Future<int> size() async {
    _checkOpened();
    return _tree.size;
  }

  @override
  Future<void> add(Key? key, NitriteId? value) async {
    _checkOpened();
    if (value != null) {
      _tree.put(_getKey(key, int.parse(value.idValue)));
    }
  }

  @override
  Future<void> remove(Key? key, NitriteId? value) async {
    _checkOpened();
    if (value != null) {
      _tree.removeId(int.parse(value.idValue));
    }
  }

  @override
  Stream<NitriteId> findIntersectingKeys(Key? key) async* {
    _checkOpened();
    var query = _getKey(key, 0);
    for (var id in _tree.intersecting(query)) {
      yield NitriteId.createId(id.toString());
    }
  }

  @override
  Stream<NitriteId> findContainedKeys(Key? key) async* {
    _checkOpened();
    var query = _getKey(key, 0);
    for (var id in _tree.contained(query)) {
      yield NitriteId.createId(id.toString());
    }
  }

  @override
  Stream<NitriteId> findNearestNeighbors(
    double x,
    double y,
    int k, [
    double? maxDistance,
  ]) async* {
    _checkOpened();
    for (var id in _tree.nearest(x, y, k, maxDistance)) {
      yield NitriteId.createId(id.toString());
    }
  }

  @override
  Future<void> clear() async {
    _checkOpened();
    _tree.clear();
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
    _tree.clear();
    await _nitriteStore.removeRTree(_mapName);
  }

  SpatialKey _getKey(Key? key, int id) {
    if (key == null || key == BoundingBox.empty) {
      return SpatialKey(id, []);
    }
    return SpatialKey(id, [key.minX, key.maxX, key.minY, key.maxY]);
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
