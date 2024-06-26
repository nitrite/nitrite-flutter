import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/store/memory/in_memory_map.dart';
import 'package:nitrite/src/store/memory/in_memory_rtree.dart';
import 'package:nitrite/src/store/memory/in_memory_store_module.dart';

/// @nodoc
class InMemoryStore extends AbstractNitriteStore<InMemoryConfig> {
  final Map<String, dynamic> _nitriteMapRegistry;
  final Map<String, dynamic> _nitriteRTreeMapRegistry;
  bool _closed = false;

  InMemoryStore(super._storeConfig)
      : _nitriteMapRegistry = <String, dynamic>{},
        _nitriteRTreeMapRegistry = <String, dynamic>{};

  @override
  bool get isClosed => _closed;

  @override
  Future<bool> get hasUnsavedChanges async => true;

  @override
  bool get isReadOnly => false;

  @override
  String get storeVersion => 'InMemory/$nitriteVersion';

  @override
  Future<void> openOrCreate() async {
    _initEventBus();
    alert(StoreEvents.opened);
  }

  @override
  Future<void> close() async {
    // close all maps and rtree
    close(MapEntry entry) => entry.value.close();
    _closed = true;

    // to avoid concurrent modification exception
    var tempMap = Map.from(_nitriteMapRegistry);
    tempMap.entries.forEach(close);

    tempMap = Map.from(_nitriteRTreeMapRegistry);
    tempMap.entries.forEach(close);

    _nitriteMapRegistry.clear();
    _nitriteRTreeMapRegistry.clear();
    await super.close();
  }

  @override
  Future<void> commit() async {
    alert(StoreEvents.commit);
  }

  @override
  Future<bool> hasMap(String mapName) async {
    return _nitriteMapRegistry.containsKey(mapName) ||
        _nitriteRTreeMapRegistry.containsKey(mapName);
  }

  @override
  Future<NitriteMap<Key, Value>> openMap<Key, Value>(String mapName) async {
    if (_nitriteMapRegistry.containsKey(mapName)) {
      var nitriteMap = _nitriteMapRegistry[mapName]!;
      if (nitriteMap.isClosed) {
        _nitriteMapRegistry.remove(mapName);
      } else {
        return nitriteMap as InMemoryMap<Key, Value>;
      }
    }

    var nitriteMap = InMemoryMap<Key, Value>(mapName, this);
    _nitriteMapRegistry[mapName] = nitriteMap;
    return nitriteMap;
  }

  @override
  Future<NitriteRTree<Key, Value>> openRTree<Key extends BoundingBox, Value>(
      String rTreeName) async {
    if (_nitriteRTreeMapRegistry.containsKey(rTreeName)) {
      return _nitriteRTreeMapRegistry[rTreeName]! as InMemoryRTree<Key, Value>;
    }

    var nitriteRTree = InMemoryRTree<Key, Value>(rTreeName, this);
    _nitriteRTreeMapRegistry[rTreeName] = nitriteRTree;
    return nitriteRTree;
  }

  @override
  Future<void> closeMap(String mapName) async {
    _nitriteMapRegistry.remove(mapName);
  }

  @override
  Future<void> closeRTree(String rTreeName) async {
    _nitriteRTreeMapRegistry.remove(rTreeName);
  }

  @override
  Future<void> removeMap(String mapName) async {
    if (_nitriteMapRegistry.containsKey(mapName)) {
      var map = _nitriteMapRegistry[mapName]!;

      if (!map.isClosed && !map.isDropped) {
        await map.close();
      }

      _nitriteMapRegistry.remove(mapName);
      var catalog = await getCatalog();
      await catalog.remove(mapName);
    }
  }

  @override
  Future<void> removeRTree(String rTreeName) async {
    if (_nitriteRTreeMapRegistry.containsKey(rTreeName)) {
      var rTree = _nitriteRTreeMapRegistry[rTreeName]!;
      await rTree.close();
      _nitriteRTreeMapRegistry.remove(rTreeName);
      var catalog = await getCatalog();
      await catalog.remove(rTreeName);
    }
  }

  void _initEventBus() {
    if (storeConfig!.eventListeners.isNotEmpty) {
      for (var listener in storeConfig!.eventListeners) {
        subscribe(listener);
      }
    }
  }
}
