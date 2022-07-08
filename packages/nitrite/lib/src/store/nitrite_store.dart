import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/store/store_catalog.dart';

/// Represents a storage interface for Nitrite database.
abstract class NitriteStore<Config extends StoreConfig> extends NitritePlugin {
  /// Opens or creates this nitrite store.
  Future<void> openOrCreate();

  /// Checks whether this store is closed.
  bool get isClosed;

  /// Gets the set of all [NitriteCollection] names in store.
  Future<Set<String>> get collectionNames;

  /// Gets the set of all [ObjectRepository] details in store.
  Future<Set<String>> get repositoryRegistry;

  /// Gets the set of all keyed-[ObjectRepository] details in store.
  Future<Map<String, Set<String>>> get keyedRepositoryRegistry;

  /// Checks whether there are any unsaved changes.
  Future<bool> get hasUnsavedChanges;

  /// Checks whether the store is opened in readonly mode.
  bool get isReadOnly;

  /// Commits the changes. For persistent stores, it also writes
  /// changes to disk. It does nothing if there are no unsaved changes.
  Future<void> commit();

  /// This method runs before store [close()], to run cleanup routines.
  Future<void> beforeClose();

  /// Checks whether a map with the name already exists in the store or not.
  Future<bool> hasMap(String mapName);

  /// Opens a [NitriteMap] with the default settings. The map is
  /// automatically created if it does not yet exist. If a map with this
  /// name is already opened, this map is returned.
  Future<NitriteMap<Key, Value>> openMap<Key, Value>(String mapName);

  /// Closes a [NitriteMap] in the store.
  Future<void> closeMap(String mapName);

  /// Removes a [NitriteMap] from the store.
  Future<void> removeMap(String mapName);

  /// Opens a [NitriteRTree] with the default settings. The RTree is
  /// automatically created if it does not yet exist. If a RTree with this
  /// name is already open, this RTree is returned.
  Future<NitriteRTree<Key, Value>> openRTree<Key extends BoundingBox, Value>(
      String rTreeName);

  /// Closes a RTree in the store.
  Future<void> closeRTree(String rTreeName);

  /// Removes a RTree from the store.
  Future<void> removeRTree(String rTreeName);

  /// Adds a [StoreEventListener] to listen to all store events.
  void subscribe(StoreEventListener listener);

  /// Removes a [StoreEventListener] to unsubscribe from all store events.
  void unsubscribe(StoreEventListener listener);

  /// Gets the underlying store engine version.
  String get storeVersion;

  /// Gets the store configuration.
  Config get storeConfig;

  /// Gets the store catalog.
  StoreCatalog get catalog;
}
