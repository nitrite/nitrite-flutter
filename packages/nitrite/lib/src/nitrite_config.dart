import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/module/plugin_manager.dart';

/// A class to configure [Nitrite] database.
class NitriteConfig {
  static String fieldSeparator = ".";

  int _schemaVersion = initialSchemaVersion;
  final Map<int, SplayTreeMap<int, Migration>> _migrations =
      <int, SplayTreeMap<int, Migration>>{};
  bool _configured = false;
  final List<NitriteModule> _modules = <NitriteModule>[];
  late PluginManager _pluginManager;

  /// Gets the [Migration] steps.
  Map<int, SplayTreeMap<int, Migration>> get migrations => _migrations;

  /// Returns the [PluginManager] instance.
  PluginManager get pluginManager => _pluginManager;

  /// Gets the current schema version.
  int get schemaVersion => _schemaVersion;

  /// Instantiates a new [NitriteConfig].
  NitriteConfig() {
    _pluginManager = PluginManager(this);
  }

  /// Sets the embedded field separator character. Default value
  /// is `.`
  void setFieldSeparator(String fieldSeparator) {
    if (_configured) {
      throw InvalidOperationException("Cannot change the separator after "
          "database initialization");
    }
    NitriteConfig.fieldSeparator = fieldSeparator;
  }

  /// Loads [NitriteModule] instance.
  NitriteConfig loadModule(NitriteModule module) {
    if (_configured) {
      throw InvalidOperationException("Cannot load module after database "
          "initialization");
    }
    _modules.add(module);
    return this;
  }

  /// Adds instructions to perform during schema migration.
  NitriteConfig addMigration(Migration migration) {
    if (_configured) {
      throw InvalidOperationException("Cannot add migration after database "
          "initialization");
    }

    if (_migrations.containsKey(migration.fromVersion)) {
      _migrations[migration.fromVersion]
          ?.putIfAbsent(migration.toVersion, () => migration);
    } else {
      _migrations.putIfAbsent(
          migration.fromVersion, () => SplayTreeMap<int, Migration>());
      _migrations[migration.fromVersion]
          ?.putIfAbsent(migration.toVersion, () => migration);
    }
    return this;
  }

  /// Sets the current schema version.
  NitriteConfig currentSchemaVersion(int version) {
    if (_configured) {
      throw InvalidOperationException("Cannot change the schema version after "
          "database initialization");
    }
    _schemaVersion = version;
    return this;
  }

  /// Autoconfigures nitrite database with default configuration values and
  /// default built-in plugins.
  Future<void> autoConfigure() async {
    if (_configured) {
      throw InvalidOperationException("Cannot auto configure after database "
          "initialization");
    }
    await _loadModules();
    return _pluginManager.findAndLoadPlugins();
  }

  /// Loads the modules.
  Future<void> _loadModules() async {
    for (NitriteModule module in _modules) {
      await _pluginManager.loadModule(module);
    }
  }

  /// Finds a [NitriteIndexer] by indexType.
  Future<NitriteIndexer> findIndexer(String indexType) async {
    var nitriteIndexer = pluginManager.indexerMap[indexType];
    if (nitriteIndexer != null) {
      await nitriteIndexer.initialize(this);
      return nitriteIndexer;
    } else {
      throw IndexingException("No indexer found for index type $indexType");
    }
  }

  /// Gets the [NitriteMapper] instance.
  NitriteMapper get nitriteMapper => pluginManager.nitriteMapper;

  /// Gets [NitriteStore] instance.
  NitriteStore<Config> getNitriteStore<Config extends StoreConfig>() {
    return pluginManager.getNitriteStore();
  }

  /// Closes the config and plugin manager.
  Future<void> close() {
    return pluginManager.close();
  }

  /// Initializes this [NitriteConfig] instance.
  Future<void> initialize() async {
    _configured = true;
    return _pluginManager.initializePlugins();
  }
}
