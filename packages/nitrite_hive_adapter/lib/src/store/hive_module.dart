import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import 'package:nitrite/nitrite.dart';

import 'hive_store.dart';

/// Configuration class for Hive store.
class HiveConfig extends StoreConfig {
  String? _path;
  HiveStorageBackendPreference _backendPreference =
      HiveStorageBackendPreference.native;
  HiveCipher? _encryptionCipher;
  CompactionStrategy? _compactionStrategy;
  bool _crashRecovery = true;
  Set<StoreEventListener> _eventListeners = {};
  Set<TypeAdapterRegistrar> _typeAdapterRegistry = {};

  @override
  void addStoreEventListener(StoreEventListener listener) {
    _eventListeners.add(listener);
  }

  @override
  Set<StoreEventListener> get eventListeners =>
      Set.unmodifiable(_eventListeners);

  @override
  String? get filePath => _path;

  @override
  bool get isReadOnly => false;

  /// Returns the backend preference for the Hive storage backend.
  HiveStorageBackendPreference get backendPreference => _backendPreference;

  /// Returns the encryption cipher used by the Hive store.
  HiveCipher? get encryptionCipher => _encryptionCipher;

  /// Returns the compaction strategy used by the Hive module.
  CompactionStrategy? get compactionStrategy => _compactionStrategy;

  /// Returns whether crash recovery is enabled or not.
  bool get crashRecovery => _crashRecovery;

  /// Returns an unmodifiable set of [TypeAdapter]s used by the Hive store.
  Set<TypeAdapterRegistrar> get typeAdapterRegistry =>
      Set.unmodifiable(_typeAdapterRegistry);

  /// Returns a new instance of [HiveConfig] with the same values as the current
  ///  instance.
  HiveConfig clone() {
    return HiveConfig()
      .._path = _path
      .._eventListeners = _eventListeners
      .._backendPreference = _backendPreference
      .._compactionStrategy = _compactionStrategy
      .._crashRecovery = _crashRecovery
      .._encryptionCipher = _encryptionCipher
      .._typeAdapterRegistry = _typeAdapterRegistry;
  }
}

/// A module for Nitrite database that uses Hive as the underlying storage engine.
class HiveModule extends StoreModule {
  late HiveConfig _storeConfig;

  /// Returns a [HiveModuleBuilder] instance to build a Hive module with configuration.
  static HiveModuleBuilder withConfig() => HiveModuleBuilder();

  /// Returns the [HiveConfig] object for the current store.
  HiveConfig get storeConfig => _storeConfig;

  /// Creates a new instance of [HiveModule] with the given [path].
  HiveModule(String? path) {
    _storeConfig = HiveConfig();
    _storeConfig._path = path;
  }

  @override
  NitriteStore<Config> getStore<Config extends StoreConfig>() {
    var store = HiveStore(_storeConfig);
    return store as NitriteStore<Config>;
  }

  @override
  Set<NitritePlugin> get plugins => {getStore()};
}

/// A builder class for creating [HiveModule] instances.
class HiveModuleBuilder {
  String? _path;
  HiveStorageBackendPreference _backendPreference =
      HiveStorageBackendPreference.native;
  HiveCipher? _encryptionCipher;
  CompactionStrategy? _compactionStrategy;
  bool _crashRecovery = true;

  late Set<StoreEventListener> _eventListeners;
  late HiveConfig _storeConfig;
  late Set<TypeAdapterRegistrar> _typeAdapterRegistry;

  /// Creates a new instance of [HiveModuleBuilder].
  HiveModuleBuilder() {
    _storeConfig = HiveConfig();
    _eventListeners = {};
    _typeAdapterRegistry = {};
  }

  /// Sets the path of the Hive database file.
  ///
  /// [value] is the path of the Hive database file.
  ///
  /// Returns a [HiveModuleBuilder] instance.
  HiveModuleBuilder path(String value) {
    _path = value;
    return this;
  }

  /// Returns a [HiveModuleBuilder] instance with the given [value] as the
  /// storage backend preference.
  HiveModuleBuilder backendPreference(HiveStorageBackendPreference value) {
    _backendPreference = value;
    return this;
  }

  /// Sets the encryption cipher for the Hive database.
  ///
  /// The [value] parameter is the encryption cipher to be used.
  ///
  /// Returns a [HiveModuleBuilder] instance.
  HiveModuleBuilder encryptionCipher(HiveCipher value) {
    _encryptionCipher = value;
    return this;
  }

  /// Sets the compaction strategy for the Hive module.
  ///
  /// The `value` parameter specifies the compaction strategy to be set.
  /// Returns a [HiveModuleBuilder] instance.
  HiveModuleBuilder compactionStrategy(CompactionStrategy value) {
    _compactionStrategy = value;
    return this;
  }

  /// Sets whether crash recovery is enabled or not.
  HiveModuleBuilder crashRecovery(bool value) {
    _crashRecovery = value;
    return this;
  }

  /// Returns a set of [StoreEventListener]s that are registered with this [HiveModule].
  Set<StoreEventListener> get eventListeners =>
      Set.unmodifiable(_eventListeners);

  /// Adds a listener to the store events.
  ///
  /// The [listener] parameter is a function that will be called whenever a
  /// store event occurs.
  HiveModuleBuilder addStoreEventListener(StoreEventListener listener) {
    _eventListeners.add(listener);
    return this;
  }

  /// Returns an unmodifiable set of [TypeAdapterRegistrar]s used by the Hive store.
  Set<TypeAdapterRegistrar> get typeAdapterRegistry =>
      Set.unmodifiable(_typeAdapterRegistry);

  /// Adds a [TypeAdapter] for the specified type [T] to the module.
  ///
  /// The [TypeAdapter] will be used to serialize and deserialize objects of
  /// type [T] when they are stored in the Hive database.
  HiveModuleBuilder addTypeAdapter<T>(TypeAdapter<T> typeAdapter) {
    _typeAdapterRegistry
        .add((HiveInterface hive) => hive.registerAdapter<T>(typeAdapter));
    return this;
  }

  /// Builds a [HiveModule] instance.
  HiveModule build() {
    var module = HiveModule(_path);

    _storeConfig._path = _path;
    _storeConfig._backendPreference = _backendPreference;
    _storeConfig._encryptionCipher = _encryptionCipher;
    _storeConfig._compactionStrategy = _compactionStrategy;
    _storeConfig._crashRecovery = _crashRecovery;
    _storeConfig._typeAdapterRegistry = _typeAdapterRegistry;
    _storeConfig._eventListeners = _eventListeners;

    module._storeConfig = _storeConfig;
    return module;
  }
}

@internal
typedef TypeAdapterRegistrar = void Function(HiveInterface);
