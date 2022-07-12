import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/store/store_catalog.dart';

abstract class AbstractNitriteStore<Config extends StoreConfig>
    implements NitriteStore<Config> {
  final EventBus _eventBus = EventBus();
  final Map<int, StreamSubscription> _subscriptions = {};

  StoreCatalog? _storeCatalog;
  late Config _storeConfig;
  late NitriteConfig _nitriteConfig;

  /// Alerts about a [StoreEvents] to all subscribed [StoreEventListener]s.
  void alert(StoreEvents eventType) {
    _eventBus.fire(EventInfo(eventType, _nitriteConfig));
  }

  @override
  Future<Set<String>> get collectionNames => catalog.collectionNames;

  @override
  Future<Set<String>> get repositoryRegistry => catalog.repositoryNames;

  @override
  Future<Map<String, Set<String>>> get keyedRepositoryRegistry =>
      catalog.keyedRepositoryNames;

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
  StoreCatalog get catalog {
    _storeCatalog ??= StoreCatalog(this);
    return _storeCatalog!;
  }

  @override
  Future<void> close() async {
    alert(StoreEvents.closed);
    _eventBus.destroy();
  }

  void setStoreConfig(Config value) {
    _storeConfig = value;
  }
}
