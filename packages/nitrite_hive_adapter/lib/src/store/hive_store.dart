// ignore_for_file: implementation_imports

import 'package:hive/hive.dart';
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

/// @nodoc
class HiveStore extends AbstractNitriteStore<HiveConfig> {
  static final Logger _log = Logger('HiveStore');

  final HiveConfig _hiveConfig;
  final _nitriteMapRegistry = <String, NitriteMap<dynamic, dynamic>>{};
  final _nitriteRTreeMapRegistry = <String, NitriteRTree<dynamic, dynamic>>{};
  bool _closed = true;

  late HiveImpl _hive;
  late KeyCodec _keyCodec;
  late Box _masterBox;

  HiveStore(this._hiveConfig) : super(_hiveConfig);

  @override
  Future<void> close() async {
    if (!_closed) {
      await _masterBox.flush();
      _closed = true;
    }

    await _hive.close();
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
  Future<bool> hasMap(String mapName) async {
    var boxName = await _findBoxName(mapName);
    return _hive.boxExists(boxName);
  }

  @override
  Future<bool> get hasUnsavedChanges async => false;

  @override
  bool get isClosed => _closed;

  @override
  bool get isReadOnly => false;

  @override
  Future<void> openOrCreate() async {
    try {
      if (_closed) {
        _hive = await openHiveDb(_hiveConfig);
        _keyCodec = KeyCodec(_hive);
        _closed = false;
        _masterBox = await _hive.openBox('__nitrite_master__');
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
    var catalog = await getCatalog();
    await catalog.remove(mapName);
    _nitriteMapRegistry.remove(mapName);
    await _removeBox(mapName);
  }

  @override
  Future<void> removeRTree(String rTreeName) async {
    var catalog = await getCatalog();
    await catalog.remove(rTreeName);
    _nitriteRTreeMapRegistry.remove(rTreeName);
    await _removeBox(rTreeName);
  }

  @override
  String get storeVersion => 'Hive/${meta['version']}';

  Future<BoxMap<Key, Value>> _openBoxMap<Key, Value>(String mapName) async {
    var encryptionCipher = _hiveConfig.encryptionCipher;
    var compactionStrategy =
        _hiveConfig.compactionStrategy ?? defaultCompactionStrategy;
    var crashRecovery = _hiveConfig.crashRecovery;
    var boxName = await _findBoxName(mapName);

    var box = await _hive.openLazyBox(boxName,
        encryptionCipher: encryptionCipher,
        compactionStrategy: compactionStrategy,
        keyComparator: nitriteKeyComparator,
        crashRecovery: crashRecovery);

    return BoxMap<Key, Value>(
        mapName, box, this, _keyCodec, nitriteKeyComparator);
  }

  Future<void> _removeBox(String mapName) async {
    var boxName = await _findBoxName(mapName);
    await _masterBox.delete(mapName);
    await _masterBox.flush();

    await _hive.deleteBoxFromDisk(boxName);
  }

  Future<String> _findBoxName(String mapName) async {
    if (_masterBox.containsKey(mapName)) {
      return _masterBox.get(mapName);
    }
    var sanitizedName = _sanitizeName(mapName);
    await _masterBox.put(mapName, sanitizedName);
    await _masterBox.flush();
    return sanitizedName;
  }

  String _sanitizeName(String mapName) {
    return mapName
        .replaceAll("\$", "_")
        .replaceAll("|", "_")
        .replaceAll(":", "_")
        .replaceAll(".", "_")
        .replaceAll("+", "_");
  }
}
