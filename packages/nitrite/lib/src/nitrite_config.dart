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
    _pluginManager = PluginManager();
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
  NitriteConfig loadModule(NitriteModule module) {
    if (_configured) {
      throw InvalidOperationException("Cannot load module after database "
          "initialization");
    }
    _pluginManager.loadModule(module);
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
  void autoConfigure() {
    if (_configured) {
      throw InvalidOperationException("Cannot auto configure after database "
          "initialization");
    }
    _pluginManager.findAndLoadPlugins();
  }

  /// Finds a [NitriteIndexer] by indexType.
  NitriteIndexer findIndexer(String indexType) {
    var nitriteIndexer = pluginManager.getIndexerMap()[indexType];
    if (nitriteIndexer != null) {
      nitriteIndexer.initialize(this);
      return nitriteIndexer;
    } else {
      throw IndexingException("No indexer found for index type $indexType");
    }
  }

  /// Gets the [NitriteMapper] instance.
  NitriteMapper get nitriteMapper => pluginManager.mapper;

  /// Gets [NitriteStore] instance.
  NitriteStore<Config> getNitriteStore<Config extends StoreConfig>() {
    return pluginManager.getNitriteStore();
  }

  void close() {
    pluginManager.close();
  }

  /// Initializes this [NitriteConfig] instance.
  void initialize() {
    _configured = true;
    _pluginManager.initializePlugins();
  }
}
