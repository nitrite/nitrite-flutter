import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/store/store_catalog.dart';

abstract class AbstractNitriteStore<Config extends StoreConfig>
    implements NitriteStore<Config> {
  final EventBus _eventBus = EventBus();
  final Map<int, StreamSubscription> _subscriptions = {};
  final Config _storeConfig;

  late StoreCatalog _storeCatalog;
  late NitriteConfig _nitriteConfig;

  AbstractNitriteStore(this._storeConfig) {
    _storeCatalog = StoreCatalog(this);
  }

  void initEventBus() {
    _storeConfig.eventListeners.forEach(subscribe);
  }

  /// Alerts about a [StoreEvents] to all subscribed [StoreEventListener]s.
  void alert(StoreEvents eventType) {
    _eventBus.fire(EventInfo(eventType, _nitriteConfig));
  }

  @override
  Future<Set<String>> get collectionNames => _storeCatalog.collectionNames;

  @override
  Future<Set<String>> get repositoryRegistry => _storeCatalog.repositoryNames;

  @override
  Future<Map<String, Set<String>>> get keyedRepositoryRegistry =>
      _storeCatalog.keyedRepositoryNames;

  @override
  Config? get storeConfig => _storeConfig;

  @override
  Future<void> beforeClose() async {
    alert(StoreEvents.closing);
  }

  @override
  Future<void> removeRTree(String rTreeName) {
    return removeMap(rTreeName);
  }

  @override
  void subscribe(StoreEventListener listener) {
    var subscription = _eventBus.on<EventInfo>().listen(listener);
    var hashCode = listener.hashCode;
    _subscriptions[hashCode] = subscription;
  }

  @override
  void unsubscribe(StoreEventListener listener) {
    var hashCode = listener.hashCode;
    var subscription = _subscriptions[hashCode];
    if (subscription != null) {
      subscription.cancel();
      _subscriptions.remove(hashCode);
    }
  }

  @override
  Future<void> initialize(NitriteConfig nitriteConfig) async {
    _nitriteConfig = nitriteConfig;
    await _storeCatalog.initialize();
  }

  @override
  Future<StoreCatalog> getCatalog() async {
    // if (!_catalogInitialized) {
    //   await _storeCatalog.initialize();
    //   _catalogInitialized = true;
    // }
    return _storeCatalog;
  }

  @override
  Future<void> close() async {
    alert(StoreEvents.closed);
    _eventBus.destroy();
  }
}
