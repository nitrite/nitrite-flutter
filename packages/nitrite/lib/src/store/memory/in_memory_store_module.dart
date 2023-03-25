import 'package:nitrite/src/common/module/nitrite_module.dart';
import 'package:nitrite/src/store/events/events.dart';
import 'package:nitrite/src/store/memory/in_memory_store.dart';
import 'package:nitrite/src/store/nitrite_store.dart';
import 'package:nitrite/src/store/store_config.dart';
import 'package:nitrite/src/store/store_module.dart';

/// The in-memory nitrite store config.
class InMemoryConfig extends StoreConfig {
  Set<StoreEventListener> _eventListeners = <StoreEventListener>{};

  @override
  void addStoreEventListener(StoreEventListener listener) {
    _eventListeners.add(listener);
  }

  @override
  String? get filePath => null;

  @override
  bool get isReadOnly => false;

  @override
  Set<StoreEventListener> get eventListeners =>
      Set.unmodifiable(_eventListeners);
}

/// The in-memory store module for nitrite.
class InMemoryStoreModule extends StoreModule {
  InMemoryConfig _storeConfig = InMemoryConfig();

  static InMemoryModuleBuilder withConfig() => InMemoryModuleBuilder._();

  @override
  NitriteStore<Config> getStore<Config extends StoreConfig>() {
    var store = InMemoryStore(_storeConfig);
    return store as NitriteStore<Config>;
  }

  @override
  Set<NitritePlugin> get plugins => <NitritePlugin>{getStore()};
}

/// The in-memory store module builder.
class InMemoryModuleBuilder {
  final Set<StoreEventListener> _eventListeners = <StoreEventListener>{};
  final InMemoryConfig _dbConfig = InMemoryConfig();

  InMemoryModuleBuilder._();

  /// Adds a [StoreEventListener] to the in-memory module builder.
  InMemoryModuleBuilder addStoreEventListener(StoreEventListener listener) {
    _eventListeners.add(listener);
    return this;
  }

  /// Builds an in-memory store module.
  InMemoryStoreModule build() {
    var module = InMemoryStoreModule();
    _dbConfig._eventListeners = _eventListeners;
    module._storeConfig = _dbConfig;
    return module;
  }
}
