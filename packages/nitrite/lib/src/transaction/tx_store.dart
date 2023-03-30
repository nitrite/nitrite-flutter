import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/transaction/tx_map.dart';
import 'package:nitrite/src/transaction/tx_rtree.dart';

class TransactionConfig extends NitriteConfig {
  final NitriteConfig _nitriteConfig;

  TransactionConfig(this._nitriteConfig) : super();

  @override
  void setFieldSeparator(String fieldSeparator) {
    _nitriteConfig.setFieldSeparator(fieldSeparator);
  }

  @override
  NitriteMapper get nitriteMapper => _nitriteConfig.nitriteMapper;
}

class TransactionStore<T extends StoreConfig> extends AbstractNitriteStore<T> {
  final NitriteStore<T> _primaryStore;
  final Map<String, NitriteMap<dynamic, dynamic>> _mapRegistry = {};
  final Map<String, NitriteRTree<dynamic, dynamic>> _rTreeRegistry = {};

  TransactionStore(this._primaryStore) : super(_primaryStore.storeConfig!);

  @override
  bool get isClosed => false;

  @override
  Future<bool> get hasUnsavedChanges async => true;

  @override
  bool get isReadOnly => false;

  @override
  String get storeVersion => _primaryStore.storeVersion;

  @override
  T? get storeConfig => null;

  @override
  Future<void> openOrCreate() async {
    // nothing to do
  }

  @override
  Future<void> commit() {
    throw InvalidOperationException('Call commit on transaction');
  }

  @override
  Future<void> close() async {
    for (var map in _mapRegistry.values) {
      await map.close();
    }

    for (var rTree in _rTreeRegistry.values) {
      await rTree.close();
    }

    _mapRegistry.clear();
    _rTreeRegistry.clear();
    await super.close();
  }

  @override
  Future<bool> hasMap(String mapName) async {
    var result = await _primaryStore.hasMap(mapName);
    if (!result) {
      result = _mapRegistry.containsKey(mapName);
      if (!result) {
        return _rTreeRegistry.containsKey(mapName);
      }
    }
    return true;
  }

  @override
  Future<NitriteMap<Key, Value>> openMap<Key, Value>(String mapName) async {
    if (_mapRegistry.containsKey(mapName)) {
      var nitriteMap = _mapRegistry[mapName]!;
      if (nitriteMap.isClosed) {
        _mapRegistry.remove(mapName);
      } else {
        return nitriteMap as NitriteMap<Key, Value>;
      }
    }

    NitriteMap<Key, Value>? primaryMap;
    if (await _primaryStore.hasMap(mapName)) {
      primaryMap = await _primaryStore.openMap<Key, Value>(mapName);
    }

    var txMap = TransactionalMap<Key, Value>(mapName, primaryMap, this);
    await txMap.initialize();
    _mapRegistry[mapName] = txMap;
    return txMap;
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
    _mapRegistry.remove(mapName);
  }

  @override
  Future<NitriteRTree<Key, Value>> openRTree<Key extends BoundingBox, Value>(
      String rTreeName) async {
    if (_rTreeRegistry.containsKey(rTreeName)) {
      return _rTreeRegistry[rTreeName] as NitriteRTree<Key, Value>;
    }

    NitriteRTree<Key, Value>? primaryRTree;
    if (await _primaryStore.hasMap(rTreeName)) {
      primaryRTree = await _primaryStore.openRTree<Key, Value>(rTreeName);
    }

    var txRtree = TransactionalRTree<Key, Value>(primaryRTree);
    await txRtree.initialize();
    _rTreeRegistry[rTreeName] = txRtree;
    return txRtree;
  }

  @override
  Future<void> removeRTree(String rTreeName) async {
    _rTreeRegistry.remove(rTreeName);
  }

  @override
  void subscribe(StoreEventListener listener) {}

  @override
  void unsubscribe(StoreEventListener listener) {}
}
