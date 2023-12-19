import 'dart:collection';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/module/plugin_manager.dart';

/// NitriteConfig is a configuration class for Nitrite database.
class NitriteConfig {
  /// The separator used to separate field names in a nested field.
  static String fieldSeparator = ".";

  int _schemaVersion = initialSchemaVersion;
  final Map<int, SplayTreeMap<int, Migration>> _migrations =
      <int, SplayTreeMap<int, Migration>>{};
  bool _configured = false;
  final List<NitriteModule> _modules = <NitriteModule>[];
  late PluginManager _pluginManager;
  final List<EntityConverter> _entityConverters = <EntityConverter>[];

  /// A map of migrations to be applied to the database.
  Map<int, SplayTreeMap<int, Migration>> get migrations => _migrations;

  /// Returns the [PluginManager] instance.
  PluginManager get pluginManager => _pluginManager;

  /// The schema version of the Nitrite database.
  int get schemaVersion => _schemaVersion;

  /// Instantiates a new [NitriteConfig].
  NitriteConfig() {
    _pluginManager = PluginManager(this);
  }

  /// Sets the field separator for Nitrite database.
  ///
  /// Throws [InvalidOperationException] if the database is already initialized.
  void setFieldSeparator(String fieldSeparator) {
    if (_configured) {
      throw InvalidOperationException("Cannot change the separator after "
          "database initialization");
    }
    NitriteConfig.fieldSeparator = fieldSeparator;
  }

  /// Loads [NitritePlugin] instances defined in the [NitriteModule]
  /// into the configuration.
  ///
  /// Throws [InvalidOperationException] if the database is already initialized.
  NitriteConfig loadModule(NitriteModule module) {
    if (_configured) {
      throw InvalidOperationException("Cannot load module after database "
          "initialization");
    }
    _modules.add(module);
    return this;
  }

  /// Registers an [EntityConverter] with Nitrite. The converter is used to
  /// convert between an entity and a [Document].
  ///
  /// Throws [InvalidOperationException] if the database is already initialized.
  void registerEntityConverter(EntityConverter<dynamic> entityConverter) {
    if (_configured) {
      throw InvalidOperationException("Cannot register entity converter after "
          "database initialization");
    }
    _entityConverters.add(entityConverter);
  }

  /// Adds a migration step to the configuration. A migration step is a process
  /// of updating the database from one version to another. If the database is
  /// already initialized, then migration steps cannot be added.
  ///
  /// Throws [InvalidOperationException] if the database is already initialized.
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

  /// Sets the current schema version of the Nitrite database.
  ///
  /// Throws [InvalidOperationException] if the database is already initialized.
  NitriteConfig currentSchemaVersion(int version) {
    if (_configured) {
      throw InvalidOperationException("Cannot change the schema version after "
          "database initialization");
    }
    _schemaVersion = version;
    return this;
  }

  /// Automatically configures Nitrite database by finding and loading plugins.
  Future<void> autoConfigure() async {
    if (_configured) {
      throw InvalidOperationException("Cannot auto configure after database "
          "initialization");
    }
    await _loadModules();
    return _pluginManager.findAndLoadPlugins();
  }

  /// Finds the [NitriteIndexer] for the given index type.
  ///
  /// Throws [IndexingException] if no indexer is found for the given index type.
  Future<NitriteIndexer> findIndexer(String indexType) async {
    var nitriteIndexer = pluginManager.indexerMap[indexType];
    if (nitriteIndexer != null) {
      await nitriteIndexer.initialize(this);
      return nitriteIndexer;
    } else {
      throw IndexingException("No indexer found for index type $indexType");
    }
  }

  /// Returns the [NitriteMapper] instance used by Nitrite.
  NitriteMapper get nitriteMapper => pluginManager.nitriteMapper;

  /// Returns the [NitriteStore] associated with this instance.
  NitriteStore<Config> getNitriteStore<Config extends StoreConfig>() {
    return pluginManager.getNitriteStore();
  }

  /// Closes the [NitriteConfig] instance and releases any resources
  /// associated with it.
  Future<void> close() {
    return pluginManager.close();
  }

  /// Initializes this [NitriteConfig] instance.
  Future<void> initialize() async {
    _configured = true;
    return _pluginManager.initializePlugins();
  }

  Future<void> _loadModules() async {
    if (_entityConverters.isNotEmpty) {
      var mapper = SimpleNitriteMapper();
      for (EntityConverter entityConverter in _entityConverters) {
        mapper.registerEntityConverter(entityConverter);
      }
      await _pluginManager.loadModule(module([mapper]));
    }

    for (NitriteModule module in _modules) {
      await _pluginManager.loadModule(module);
    }
  }
}
