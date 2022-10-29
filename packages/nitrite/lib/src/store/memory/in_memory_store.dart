import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/store/memory/in_memory_map.dart';
import 'package:nitrite/src/store/memory/in_memory_rtree.dart';
import 'package:nitrite/src/store/memory/in_memory_store_module.dart';

class InMemoryStore extends AbstractNitriteStore<InMemoryConfig> {
  final Map<String, NitriteMap<dynamic, dynamic>> _nitriteMapRegistry;
  final Map<String, NitriteRTree<dynamic, dynamic>> _nitriteRTreeMapRegistry;
  bool _closed = false;

  InMemoryStore()
      : _nitriteMapRegistry = <String, NitriteMap<dynamic, dynamic>>{},
        _nitriteRTreeMapRegistry = <String, NitriteRTree<dynamic, dynamic>>{};

  @override
  bool get isClosed => _closed;

  @override
  Future<bool> get hasUnsavedChanges async => false;

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
    _closed = true;

    var futures = <Future<void>>[];
    for (var map in _nitriteMapRegistry.values) {
      // close all maps in parallel
      futures.add(map.close());
    }
    await Future.wait(futures);

    futures.clear();
    for (var rtree in _nitriteRTreeMapRegistry.values) {
      // close all rtree in parallel
      futures.add(rtree.close());
    }
    await Future.wait(futures);

    _nitriteMapRegistry.clear();
    _nitriteRTreeMapRegistry.clear();
    super.close();
  }

  @override
  Future<void> commit() async {
    alert(StoreEvents.commit);
  }

  @override
  Future<bool> hasMap(String mapName) async {
    return _nitriteMapRegistry.containsKey(mapName)
        || _nitriteRTreeMapRegistry.containsKey(mapName);
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
  Future<void> closeMap(String mapName) async {
    // nothing to close as it is volatile map, moreover,
    // removing it from registry means losing the map
  }

  @override
  Future<void> closeRTree(String rTreeName) async {
    // nothing to close as it is volatile map, moreover,
    // removing it from registry means losing the map
  }

  @override
  Future<void> removeMap(String mapName) async {
    if (_nitriteMapRegistry.containsKey(mapName)) {
      var map = _nitriteMapRegistry[mapName]!;

      if (!map.isClosed && !map.isDropped) {
        await map.clear();
        await map.close();
      }

      _nitriteMapRegistry.remove(mapName);
      await catalog.remove(mapName);
    }
  }

  @override
  Future<NitriteRTree<Key, Value>> openRTree<Key extends BoundingBox, Value>(
      String rTreeName) async {
    if (_nitriteRTreeMapRegistry.containsKey(rTreeName)) {
      return _nitriteRTreeMapRegistry[rTreeName]! as InMemoryRTree<Key, Value>;
    }

    var nitriteRTree = InMemoryRTree<Key, Value>();
    _nitriteRTreeMapRegistry[rTreeName] = nitriteRTree;
    return nitriteRTree;
  }

  void _initEventBus() {
    if (storeConfig!.eventListeners.isNotEmpty) {
      for (var listener in storeConfig!.eventListeners) {
        subscribe(listener);
      }
    }
  }
}
