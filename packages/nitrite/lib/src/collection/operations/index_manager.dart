import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/index_utils.dart';
import 'package:nitrite/src/index/types.dart';

class IndexManager {
  final NitriteConfig _nitriteConfig;
  final NitriteStore _nitriteStore;
  final String _collectionName;

  Iterable<IndexDescriptor>? _indexDescriptorCache;
  late NitriteMap<Fields, IndexMeta> _indexMetaMap;

  IndexManager(this._collectionName, this._nitriteConfig)
      : _nitriteStore = _nitriteConfig.getNitriteStore();

  Future<void> initialize() async {
    var mapName = deriveIndexMetaMapName(_collectionName);
    _indexMetaMap = await _nitriteStore.openMap<Fields, IndexMeta>(mapName);
    await _updateIndexDescriptorCache();
  }

  Future<bool> hasIndexDescriptor(Fields fields) async {
    var indexDescriptors = await findMatchingIndexDescriptors(fields);
    return indexDescriptors.isNotEmpty;
  }

  Future<Iterable<IndexDescriptor>> getIndexDescriptors() async {
    _indexDescriptorCache ??= await listIndexDescriptors();
    return _indexDescriptorCache!;
  }

  Future<Iterable<IndexDescriptor>> findMatchingIndexDescriptors(
      Fields fields) async {
    var list = <IndexDescriptor>[];
    var indexDescriptors = await getIndexDescriptors();
    for (var indexDescriptor in indexDescriptors) {
      if (indexDescriptor.fields.startWith(fields)) {
        list.add(indexDescriptor);
      }
    }
    return list;
  }

  Future<IndexDescriptor?> findExactIndexDescriptor(Fields fields) async {
    var meta = await _indexMetaMap[fields];
    if (meta != null) {
      return meta.indexDescriptor;
    }
    return null;
  }

  Future<void> close() async {
    // close all index maps
    if (!_indexMetaMap.isClosed && !_indexMetaMap.isDropped) {
      var futures = <Future<void>>[];

      await for (var indexMeta in _indexMetaMap.values()) {
        if (indexMeta.indexDescriptor != null) {
          var indexMapName = indexMeta.indexMap;

          if (indexMapName != null) {
            // run all futures in parallel
            futures.add(Future.microtask(() async {
              var indexMap =
              await _nitriteStore.openMap<dynamic, dynamic>(indexMapName);
              await indexMap.close();
            }));
          }
        }
      }

      await Future.wait(futures);
      // close index meta
      await _indexMetaMap.close();
    }
  }

  Future<bool> isDirtyIndex(Fields fields) async {
    var meta = await _indexMetaMap[fields];
    if (meta != null) {
      return meta.isDirty;
    }
    return false;
  }

  Future<Iterable<IndexDescriptor>> listIndexDescriptors() async {
    var list = <IndexDescriptor>[];
    var iterable = _indexMetaMap.values();
    await for (var indexMeta in iterable) {
      var indexDescriptor = indexMeta.indexDescriptor;
      if (indexDescriptor != null) {
        list.add(indexDescriptor);
      }
    }
    return list;
  }

  Future<IndexDescriptor> createIndexDescriptor(
      Fields fields, String indexType) async {
    await _validateIndexRequest(fields, indexType);
    var index = IndexDescriptor(indexType, fields, _collectionName);

    var indexMeta = IndexMeta();
    indexMeta.indexDescriptor = index;
    indexMeta.indexMap = deriveIndexMapName(index);
    indexMeta.isDirty = false;

    await _indexMetaMap.put(fields, indexMeta);
    await _updateIndexDescriptorCache();
    return index;
  }

  Future<void> dropIndexDescriptor(Fields fields) async {
    var indexMeta = await _indexMetaMap[fields];
    if (indexMeta != null) {
      var indexMapName = indexMeta.indexMap;
      if (indexMapName != null) {
        var indexMap =
            await _nitriteStore.openMap<dynamic, dynamic>(indexMapName);
        await indexMap.drop();
      }

      await _indexMetaMap.remove(fields);
      await _updateIndexDescriptorCache();
    }
  }

  Future<void> dropIndexMeta() async {
    await _indexMetaMap.drop();
  }

  Future<void> beginIndexing(Fields fields) {
    return _markDirty(fields, true);
  }

  Future<void> endIndexing(Fields fields) {
    return _markDirty(fields, false);
  }

  Future<void> clearAll() async {
    // close all index maps
    if (!_indexMetaMap.isClosed && !_indexMetaMap.isDropped) {
      var futures = <Future<void>>[];

      await for (var indexMeta in _indexMetaMap.values()) {
        if (indexMeta.indexDescriptor != null) {
          var indexMapName = indexMeta.indexMap;

          if (indexMapName != null) {
            // run all futures in parallel
            futures.add(Future.microtask(() async {
              var indexMap =
              await _nitriteStore.openMap<dynamic, dynamic>(indexMapName);
              await indexMap.clear();
            }));
          }
        }
      }

      await Future.wait(futures);
    }
  }

  Future<void> _markDirty(Fields fields, bool dirty) async {
    var meta = await _indexMetaMap[fields];
    if (meta != null) {
      meta.isDirty = dirty;
      await _indexMetaMap.put(fields, meta);
    }
  }

  Future<void> _updateIndexDescriptorCache() async {
    _indexDescriptorCache = await listIndexDescriptors();
  }

  Future<void> _validateIndexRequest(Fields fields, String indexType) async {
    var indexer = await _nitriteConfig.findIndexer(indexType);
    await indexer.validateIndex(fields);
  }
}
