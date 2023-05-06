// ignore_for_file: implementation_imports

import 'package:hive/src/box/default_compaction_strategy.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:logging/logging.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_hive_adapter/src/store/box_map.dart';
import 'package:nitrite_hive_adapter/src/store/hive_meta.dart';
import 'package:nitrite_hive_adapter/src/store/key_encoder.dart';

import 'box_tree.dart';
import 'hive_module.dart';
import 'hive_utils.dart';

class HiveStore extends AbstractNitriteStore<HiveConfig> {
  static final Logger _log = Logger('HiveStore');

  final HiveConfig _hiveConfig;
  final _nitriteMapRegistry = <String, NitriteMap<dynamic, dynamic>>{};
  final _nitriteRTreeMapRegistry = <String, NitriteRTree<dynamic, dynamic>>{};
  bool _closed = true;

  late HiveImpl _hive;
  late KeyCodec _keyCodec;

  HiveStore(this._hiveConfig) : super(_hiveConfig);

  @override
  Future<void> close() async {
    if (!_closed) {
      await _hive.close();
      _closed = true;
    }

    _nitriteMapRegistry.clear();
    _nitriteRTreeMapRegistry.clear();
    return super.close();
  }

  @override
  Future<void> closeMap(String mapName) async {
    if (mapName.isNotEmpty) {
      _nitriteMapRegistry.remove(mapName);
    }
  }

  @override
  Future<void> closeRTree(String rTreeName) async {
    if (rTreeName.isNotEmpty) {
      _nitriteRTreeMapRegistry.remove(rTreeName);
    }
  }

  @override
  Future<void> commit() async {
    alert(StoreEvents.commit);
  }

  @override
  Future<bool> hasMap(String mapName) {
    return _hive.boxExists(mapName);
  }

  @override
  Future<bool> get hasUnsavedChanges async => false;

  @override
  bool get isClosed => _closed;

  @override
  bool get isReadOnly => false;

  @override
  Future<NitriteMap<Key, Value>> openMap<Key, Value>(String mapName) async {
    if (_nitriteMapRegistry.containsKey(mapName)) {
      return _nitriteMapRegistry[mapName] as NitriteMap<Key, Value>;
    } else {
      var nitriteMap = await _openBoxMap<Key, Value>(mapName);
      _nitriteMapRegistry[mapName] = nitriteMap;
      return nitriteMap;
    }
  }

  @override
  Future<void> openOrCreate() async {
    try {
      if (_closed) {
        _hive = await openHiveDb(_hiveConfig);
        _keyCodec = KeyCodec(_hive);
        _closed = false;
        initEventBus();
        alert(StoreEvents.opened);
      }
    } catch (e, s) {
      _log.severe('Error while opening database', e, s);
      throw NitriteIOException('Failed to open database',
          cause: e, stackTrace: s);
    }
  }

  @override
  Future<NitriteRTree<Key, Value>> openRTree<Key extends BoundingBox, Value>(
      String rTreeName) async {
    if (_nitriteRTreeMapRegistry.containsKey(rTreeName)) {
      return _nitriteRTreeMapRegistry[rTreeName] as NitriteRTree<Key, Value>;
    } else {
      var nitriteMap = await _openBoxMap<SpatialKey, Key>(rTreeName);
      var rTree = BoxTree<Key, Value>(nitriteMap);
      _nitriteRTreeMapRegistry[rTreeName] = rTree;
      return rTree;
    }
  }

  @override
  Future<void> removeMap(String mapName) async {
    _hive.unregisterBox(mapName);
    var catalog = await getCatalog();
    catalog.remove(mapName);
    _nitriteMapRegistry.remove(mapName);
    await _hive.deleteBoxFromDisk(mapName);
  }

  @override
  Future<void> removeRTree(String rTreeName) async {
    _hive.unregisterBox(rTreeName);
    var catalog = await getCatalog();
    catalog.remove(rTreeName);
    _nitriteRTreeMapRegistry.remove(rTreeName);
    await _hive.deleteBoxFromDisk(rTreeName);
  }

  @override
  String get storeVersion => 'Hive/${meta['version']}';

  Future<BoxMap<Key, Value>> _openBoxMap<Key, Value>(String mapName) async {
    var encryptionCipher = _hiveConfig.encryptionCipher;
    var compactionStrategy =
        _hiveConfig.compactionStrategy ?? defaultCompactionStrategy;
    var crashRecovery = _hiveConfig.crashRecovery;

    var box = await _hive.openLazyBox(mapName,
        encryptionCipher: encryptionCipher,
        compactionStrategy: compactionStrategy,
        keyComparator: nitriteKeyComparator,
        crashRecovery: crashRecovery);

    return BoxMap<Key, Value>(
        mapName, box, this, _keyCodec, nitriteKeyComparator);
  }
}
