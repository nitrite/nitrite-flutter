import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/module/plugin_manager.dart';

/// A class to configure [Nitrite] database.
class NitriteConfig {
  static String fieldSeparator = ".";

  int _schemaVersion = initialSchemaVersion;
  late PluginManager _pluginManager;
  late Map<int, SplayTreeMap<int, Migration>> _migrations;
  bool _configured = false;

  /// Gets the [Migration] steps.
  Map<int, SplayTreeMap<int, Migration>> get migrations => _migrations;

  /// Returns the [PluginManager] instance.
  PluginManager get pluginManager => _pluginManager;

  /// Gets the current schema version.
  int get schemaVersion => _schemaVersion;

  /// Instantiates a new [NitriteConfig].
  NitriteConfig() {
    _pluginManager = PluginManager(this);
    _migrations = <int, SplayTreeMap<int, Migration>>{};
  }

  /// Sets the embedded field separator character. Default value
  /// is `.`
  setFieldSeparator(String fieldSeparator) {
    if (_configured) {
      throw InvalidOperationException("Cannot change the separator after "
          "database initialization");
    }
    NitriteConfig.fieldSeparator = fieldSeparator;
  }

  /// Loads [NitriteModule] instance.
  Future<NitriteConfig> loadModule(NitriteModule module) async {
    if (_configured) {
      throw InvalidOperationException("Cannot load module after database "
          "initialization");
    }
    await _pluginManager.loadModule(module);
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
    return _pluginManager.findAndLoadPlugins();
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

  Future<void> close() {
    return pluginManager.close();
  }

  /// Initializes this [NitriteConfig] instance.
  Future<void> initialize() {
    _configured = true;
    return _pluginManager.initializePlugins();
  }
}
