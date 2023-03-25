import 'package:hive/hive.dart';
import 'package:nitrite/nitrite.dart';

import 'hive_store.dart';

class HiveConfig extends StoreConfig {
  String? _path;
  HiveStorageBackendPreference _backendPreference =
      HiveStorageBackendPreference.native;
  HiveCipher? _encryptionCipher;
  CompactionStrategy? _compactionStrategy;
  bool _crashRecovery = true;
  Set<StoreEventListener> _eventListeners = {};
  Set<TypeAdapter<dynamic>> _typeAdapters = {};

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

  HiveStorageBackendPreference get backendPreference => _backendPreference;

  HiveCipher? get encryptionCipher => _encryptionCipher;

  CompactionStrategy? get compactionStrategy => _compactionStrategy;

  bool get crashRecovery => _crashRecovery;

  Set<TypeAdapter<dynamic>> get typeAdapters => Set.unmodifiable(_typeAdapters);

  HiveConfig clone() {
    return HiveConfig()
      .._path = _path
      .._eventListeners = _eventListeners
      .._backendPreference = _backendPreference
      .._compactionStrategy = _compactionStrategy
      .._crashRecovery = _crashRecovery
      .._encryptionCipher = _encryptionCipher
      .._typeAdapters = _typeAdapters;
  }
}

class HiveModule extends StoreModule {
  late HiveConfig _storeConfig;

  static HiveModuleBuilder withConfig() => HiveModuleBuilder();

  HiveConfig get storeConfig => _storeConfig;

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

class HiveModuleBuilder {
  String? _path;
  HiveStorageBackendPreference _backendPreference =
      HiveStorageBackendPreference.native;
  HiveCipher? _encryptionCipher;
  CompactionStrategy? _compactionStrategy;
  bool _crashRecovery = true;

  late Set<StoreEventListener> _eventListeners;
  late HiveConfig _storeConfig;
  late Set<TypeAdapter<dynamic>> _typeAdapters;

  HiveModuleBuilder() {
    _storeConfig = HiveConfig();
    _eventListeners = {};
    _typeAdapters = {};
  }

  HiveModuleBuilder path(String value) {
    _path = value;
    return this;
  }

  HiveModuleBuilder backendPreference(HiveStorageBackendPreference value) {
    _backendPreference = value;
    return this;
  }

  HiveModuleBuilder encryptionCipher(HiveCipher value) {
    _encryptionCipher = value;
    return this;
  }

  HiveModuleBuilder compactionStrategy(CompactionStrategy value) {
    _compactionStrategy = value;
    return this;
  }

  HiveModuleBuilder crashRecovery(bool value) {
    _crashRecovery = value;
    return this;
  }

  Set<StoreEventListener> get eventListeners =>
      Set.unmodifiable(_eventListeners);
  void addStoreEventListener(StoreEventListener listener) {
    _eventListeners.add(listener);
  }

  Set<TypeAdapter<dynamic>> get typeAdapters => Set.unmodifiable(_typeAdapters);
  void addTypeAdapter<T>(TypeAdapter<T> typeAdapter) {
    _typeAdapters.add(typeAdapter);
  }

  HiveModule build() {
    var module = HiveModule(_path);

    _storeConfig._path = _path;
    _storeConfig._backendPreference = _backendPreference;
    _storeConfig._encryptionCipher = _encryptionCipher;
    _storeConfig._compactionStrategy = _compactionStrategy;
    _storeConfig._crashRecovery = _crashRecovery;
    _storeConfig._typeAdapters = _typeAdapters;
    _storeConfig._eventListeners = _eventListeners;

    module._storeConfig = _storeConfig;
    return module;
  }
}
