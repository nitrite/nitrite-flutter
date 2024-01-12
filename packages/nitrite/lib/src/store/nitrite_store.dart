import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/store/store_catalog.dart';

/// Represents a storage interface for Nitrite database.
abstract class NitriteStore<Config extends StoreConfig> extends NitritePlugin {
  /// Opens the store if it exists, or creates a new one if it doesn't.
  Future<void> openOrCreate();

  /// Checks whether this store is closed.
  bool get isClosed;

  /// Returns a [Future] that completes with a [Set] of all
  /// collection names in the Nitrite database.
  Future<Set<String>> get collectionNames;

  /// Returns a [Future] that completes with a [Set] of all
  /// repository names in the Nitrite database.
  Future<Set<String>> get repositoryRegistry;

  /// Gets the set of all keyed-[ObjectRepository] details in
  /// the Nitrite database.
  Future<Map<String, Set<String>>> get keyedRepositoryRegistry;

  /// Returns a [Future] that completes with a [bool] indicating
  /// whether there are unsaved changes in the Nitrite store.
  Future<bool> get hasUnsavedChanges;

  /// Checks whether the store is opened in readonly mode.
  bool get isReadOnly;

  /// Commits the changes. For persistent stores, it also writes
  /// changes to disk. It does nothing if there are no unsaved changes.
  Future<void> commit();

  /// This method is called before closing the store. Any resource cleanup
  /// tasks should be performed in this method.
  Future<void> beforeClose();

  /// Returns a Future that completes with a boolean value indicating whether
  /// a [NitriteMap] with the given name exists in the store.
  Future<bool> hasMap(String mapName);

  /// Opens a [NitriteMap] with the given [mapName] and returns a [Future]
  /// that completes with the opened map.
  ///
  /// The map is automatically created if it does not yet exist.
  /// If a map with this name is already opened, this map is returned.
  ///
  /// The [Key] and [Value] types are generic and should be specified
  /// when calling this method.
  Future<NitriteMap<Key, Value>> openMap<Key, Value>(String mapName);

  /// Closes a [NitriteMap] with the specified name in the store.
  Future<void> closeMap(String mapName);

  /// Removes a [NitriteMap] with the specified name from the store.
  Future<void> removeMap(String mapName);

  /// Opens an [NitriteRTree] with the given key and value types. The key type must
  /// extend the [BoundingBox] class. Returns a [NitriteRTree] instance that can
  /// be used to perform R-Tree operations on the data.
  ///
  /// The R-Tree is automatically created if it does not yet exist. If a R-Tree
  /// with this name is already open, this R-Tree is returned.
  ///
  /// The [Key] and [Value] types are generic and should be specified when
  /// calling this method.
  Future<NitriteRTree<Key, Value>> openRTree<Key extends BoundingBox, Value>(
      String rTreeName);

  /// Closes a [NitriteRTree] with the specified name in the store.
  Future<void> closeRTree(String rTreeName);

  /// Removes a [NitriteRTree] with the specified name from the store.
  Future<void> removeRTree(String rTreeName);

  /// Subscribes a [StoreEventListener] to this store. The listener will be
  /// notified of any changes made to the store.
  void subscribe(StoreEventListener listener);

  /// Unsubscribes a [StoreEventListener] from this store.
  void unsubscribe(StoreEventListener listener);

  /// Gets the underlying storage engine version.
  String get storeVersion;

  /// Gets the store configuration.
  Config? get storeConfig;

  /// Gets the store catalog.
  Future<StoreCatalog> getCatalog();
}
