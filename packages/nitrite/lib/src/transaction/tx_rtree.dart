import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/spatial_key.dart';
import 'package:nitrite/src/store/memory/in_memory_rtree.dart';
import 'package:rxdart/rxdart.dart';

class TransactionalRTree<Key extends BoundingBox, Value>
    extends NitriteRTree<Key, Value> {
  final Map<SpatialKey, Key> _map;
  final NitriteRTree<Key, Value> _primaryRTree;

  TransactionalRTree(NitriteRTree<Key, Value>? primaryRTree) :
      _primaryRTree = primaryRTree ?? InMemoryRTree<Key, Value>(),
      _map = <SpatialKey, Key>{};

  @override
  Future<int> get size async => _map.length;

  @override
  Future<void> add(Key key, NitriteId? value) async {
    if (value != null && value.idValue.isNotEmpty) {
      var spatialKey = _getKey(key, int.parse(value.idValue));
      _map[spatialKey] = key;
    }
  }

  @override
  Future<void> remove(Key key, NitriteId? value) async {
    if (value != null && value.idValue.isNotEmpty) {
      var spatialKey = _getKey(key, int.parse(value.idValue));
      _map.remove(spatialKey);
    }
  }

  @override
  Stream<NitriteId> findIntersectingKeys(Key key) {
    var spatialKey = _getKey(key, 0);
    var set = <NitriteId>{};

    for (var sk in _map.keys) {
      if (_isOverlap(sk, spatialKey)) {
        set.add(NitriteId.createId(sk.id.toString()));
      }
    }

    var primaryRecords = _primaryRTree.findIntersectingKeys(key);
    return ConcatStream([
      primaryRecords,
      Stream.fromIterable(set),
    ]);
  }

  @override
  Stream<NitriteId> findContainedKeys(Key key) {
    var spatialKey = _getKey(key, 0);
    var set = <NitriteId>{};

    for (var sk in _map.keys) {
      if (_isInside(sk, spatialKey)) {
        set.add(NitriteId.createId(sk.id.toString()));
      }
    }

    var primaryRecords = _primaryRTree.findContainedKeys(key);
    return ConcatStream([
      primaryRecords,
      Stream.fromIterable(set),
    ]);
  }


  @override
  Future<void> clear() async {
    _map.clear();
  }

  @override
  Future<void> close() async {
    _map.clear();
  }

  @override
  Future<void> drop() async {
    _map.clear();
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

  @override
  Future<void> initialize() async {
  }

}
