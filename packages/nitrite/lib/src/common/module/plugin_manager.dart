import 'package:logging/logging.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:nitrite/src/index/comparable_indexer.dart';
import 'package:nitrite/src/index/nitrite_text_indexer.dart';
import 'package:nitrite/src/store/memory/in_memory_store_module.dart';

/// @nodoc
class PluginManager {
  static final Logger _log = Logger('PluginManager');

  final List<EntityConverter> _entityConverters = [];
  final Map<String, NitriteIndexer> _indexerMap = {};
  final NitriteConfig _nitriteConfig;

  NitriteMapper? _nitriteMapper;
  NitriteStore? _nitriteStore;

  PluginManager(this._nitriteConfig);

  Map<String, NitriteIndexer> get indexerMap => _indexerMap;
  NitriteMapper get nitriteMapper => _nitriteMapper!;

  NitriteStore<Config> getNitriteStore<Config extends StoreConfig>() =>
      _nitriteStore! as NitriteStore<Config>;

  Future<void> loadModule(NitriteModule module) async {
    if (!module.plugins.isNullOrEmpty) {
      for (var plugin in module.plugins) {
        // load all plugins in parallel
        await _loadPlugin(plugin);
      }
    }
  }

  Future<void> findAndLoadPlugins() async {
    try {
      await _loadInternalPlugins();
    } catch (e, stackTrace) {
      throw PluginException("Error loading plugins",
          stackTrace: stackTrace, cause: e);
    }
  }

  Future<void> initializePlugins() async {
    if (_nitriteStore != null) {
      await _initializePlugin(_nitriteStore!);
    } else {
      throw NitriteIOException('No nitrite storage engine found');
    }

    if (_nitriteMapper != null) {
      await _initializePlugin(_nitriteMapper!);
    }

    if (_indexerMap.isNotEmpty) {
      for (var indexer in _indexerMap.values) {
        // initialize all indexers in parallel
        await _initializePlugin(indexer);
      }
    }
  }

  Future<void> close() async {
    for (var indexer in _indexerMap.values) {
      // close all indexers in parallel
      await indexer.close();
    }

    await _nitriteMapper?.close();
    await _nitriteStore?.close();
  }

  Future<void> _loadPlugin(NitritePlugin plugin) async {
    return _populatePlugins(plugin);
  }

  Future<void> _initializePlugin(NitritePlugin plugin) {
    return plugin.initialize(_nitriteConfig);
  }

  Future<void> _populatePlugins(NitritePlugin plugin) async {
    if (plugin is NitriteIndexer) {
      await _loadIndexer(plugin);
    } else if (plugin is NitriteMapper) {
      await _loadNitriteMapper(plugin);
    } else if (plugin is NitriteStore) {
      await _loadNitriteStore(plugin);
    } else if (plugin is EntityConverter) {
      await _loadEntityConverter(plugin);
    } else {
      await plugin.close();
      throw PluginException("Unknown plugin type: ${plugin.runtimeType}");
    }
  }

  Future<void> _loadNitriteStore(NitriteStore plugin) async {
    if (_nitriteStore != null) {
      await plugin.close();
      throw PluginException("Multiple nitrite store plugins found");
    }
    _nitriteStore = plugin;
  }

  Future<void> _loadNitriteMapper(NitriteMapper plugin) async {
    if (_nitriteMapper != null) {
      await plugin.close();
      throw PluginException("Multiple nitrite mapper plugins found");
    }
    _nitriteMapper = plugin;
  }

  Future<void> _loadIndexer(NitriteIndexer plugin) async {
    if (_indexerMap.containsKey(plugin.indexType)) {
      await plugin.close();
      throw PluginException("Multiple indexer plugins found for type: "
          "${plugin.indexType}");
    }
    _indexerMap[plugin.indexType] = plugin;
  }

  Future<void> _loadEntityConverter(EntityConverter plugin) async {
    _entityConverters.add(plugin);
  }

  Future<void> _loadInternalPlugins() async {
    if (!_indexerMap.containsKey(IndexType.unique)) {
      _log.fine("Loading default unique indexer");
      var plugin = UniqueIndexer();
      await _loadPlugin(plugin);
    }

    if (!_indexerMap.containsKey(IndexType.nonUnique)) {
      _log.fine("Loading default non-unique indexer");
      var plugin = NonUniqueIndexer();
      await _loadPlugin(plugin);
    }

    if (!_indexerMap.containsKey(IndexType.fullText)) {
      _log.fine("Loading nitrite text indexer");
      var plugin = NitriteTextIndexer();
      await _loadPlugin(plugin);
    }

    if (_nitriteMapper == null) {
      _log.fine("Loading nitrite mapper");
      var plugin = SimpleNitriteMapper();
      await _loadPlugin(plugin);
    }

    if (_nitriteMapper != null && _nitriteMapper is SimpleNitriteMapper) {
      if (_nitriteConfig.entityConverters.isNotEmpty) {
        for (var converter in _nitriteConfig.entityConverters) {
          (_nitriteMapper as SimpleNitriteMapper)
              .registerEntityConverter(converter);
        }
      }

      for (var converter in _entityConverters) {
        (_nitriteMapper as SimpleNitriteMapper)
            .registerEntityConverter(converter);
      }
    }

    if (_nitriteStore == null) {
      await loadModule(InMemoryStoreModule());
      _log.warning('No persistent storage module found, creating an '
          'in-memory storage');
    }
  }
}
