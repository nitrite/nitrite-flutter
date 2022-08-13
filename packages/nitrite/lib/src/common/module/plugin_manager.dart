import 'package:logging/logging.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/mapper/mappable_mapper.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';
import 'package:nitrite/src/index/comparable_indexer.dart';
import 'package:nitrite/src/index/nitrite_text_indexer.dart';
import 'package:nitrite/src/store/memory/in_memory_store_module.dart';

/// The nitrite database plugin manager. It loads the nitrite plugins
/// before opening the database.
class PluginManager {
  static final Logger _log = Logger('PluginManager');

  final Map<String, NitriteIndexer> _indexerMap = {};
  final NitriteConfig _nitriteConfig;

  NitriteMapper? _nitriteMapper;
  NitriteStore? _nitriteStore;

  /// Creates a new [PluginManager] instance.
  PluginManager(this._nitriteConfig);

  Map<String, NitriteIndexer> get indexerMap => _indexerMap;
  NitriteMapper get nitriteMapper => _nitriteMapper!;

  NitriteStore<Config> getNitriteStore<Config extends StoreConfig>() =>
      _nitriteStore! as NitriteStore<Config>;

  /// Loads a [NitriteModule] instance.
  Future<void> loadModule(NitriteModule module) async {
    if (!module.plugins.isNullOrEmpty) {

      var futures = <Future<void>>[];
      for (var plugin in module.plugins) {
        // load all plugins in parallel
        futures.add(_loadPlugin(plugin));
      }
      await Future.wait(futures);
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
      var futures = <Future<void>>[];
      for (var indexer in _indexerMap.values) {
        // initialize all indexers in parallel
        futures.add(_initializePlugin(indexer));
      }
      await Future.wait(futures);
    }
  }

  Future<void> close() async {
    var futures = <Future<void>>[];
    for (var indexer in _indexerMap.values) {
      // close all indexers in parallel
      futures.add(indexer.close());
    }
    await Future.wait(futures);

    await _nitriteMapper?.close();
    return _nitriteStore?.close();
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
      var plugin = MappableMapper();
      await _loadPlugin(plugin);
    }

    if (_nitriteStore == null) {
      await loadModule(InMemoryStoreModule());
      _log.warning('No persistent storage module found, creating an '
          'in-memory database');
    }
  }
}
