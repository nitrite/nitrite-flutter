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
  bool _catalogInitialized = false;

  AbstractNitriteStore(this._storeConfig);

  void initEventBus() {
    _storeConfig.eventListeners.forEach(subscribe);
  }

  /// Alerts about a [StoreEvents] to all subscribed [StoreEventListener]s.
  void alert(StoreEvents eventType) {
    _eventBus.fire(EventInfo(eventType, _nitriteConfig));
  }

  @override
  Future<Set<String>> get collectionNames async {
    var catalog = await getCatalog();
    return catalog.collectionNames;
  }

  @override
  Future<Set<String>> get repositoryRegistry async {
    var catalog = await getCatalog();
    return catalog.repositoryNames;
  }

  @override
  Future<Map<String, Set<String>>> get keyedRepositoryRegistry async {
    var catalog = await getCatalog();
    return catalog.keyedRepositoryNames;
  }

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
  }

  @override
  Future<StoreCatalog> getCatalog() async {
    if (!_catalogInitialized) {
      _storeCatalog = StoreCatalog(this);
      await _storeCatalog.initialize();
      _catalogInitialized = true;
    }
    return _storeCatalog;
  }

  @override
  Future<void> close() async {
    alert(StoreEvents.closed);
    _eventBus.destroy();
  }
}
