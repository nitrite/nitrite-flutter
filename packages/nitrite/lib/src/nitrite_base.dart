import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

/// An in-memory, single-file based embedded nosql persistent document store. The store
/// can contains multiple named document collections.
abstract class Nitrite {
  /// Returns an instance of a [NitriteBuilder].
  static NitriteBuilder builder() {
    return NitriteBuilder();
  }

  /// Commits the unsaved changes. For file based store, it saves the changes
  /// to disk if there are any unsaved changes.
  ///
  /// No need to call it after every change, if auto-commit is not disabled
  /// while opening the db. However, it may still be called to flush all
  /// changes to disk.
  Future<void> commit();

  /// Opens a named collection from the store. If the collections does not
  /// exist it will be created automatically and returned. If a collection
  /// is already opened, it is returned as is. Returned collection is thread-safe
  /// for concurrent use.
  ///
  /// The name cannot contain below reserved strings:
  ///
  /// * [internalNameSeparator]
  /// * [userMap]
  /// * [indexMetaPrefix]
  /// * [indexPrefix]
  /// * [objectStoreNameSeparator]
  ///
  Future<NitriteCollection> getCollection(String name);

  /// Opens a type-safe object repository with an optional key identifier from
  /// the store. If the repository does not exist it will be created
  /// automatically and returned. If a repository is already opened, it is
  /// returned as is.
  ///
  /// If the entity type [T] cannot be annotated with [Entity], an
  /// [EntityDecorator] implementation of the type can also be provided
  /// to create an object repository.
  ///
  /// The returned repository is thread-safe for concurrent use.
  Future<ObjectRepository<T>> getRepository<T>(
      {EntityDecorator<T>? entityDecorator, String? key});

  /// Destroys a [NitriteCollection] without opening it first.
  Future<void> destroyCollection(String name);

  /// Destroys an [ObjectRepository] without opening it first.
  Future<void> destroyRepository<T>(
      {EntityDecorator<T>? entityDecorator, String? key});

  /// Gets the set of all [NitriteCollection]s' names saved in the store.
  Future<Set<String>> get listCollectionNames;

  /// Gets the set of all fully qualified class names corresponding
  /// to all [ObjectRepository]s in the store.
  Future<Set<String>> get listRepositories;

  /// Gets the map of all key to the fully qualified class names corresponding
  /// to all keyed-[ObjectRepository]s in the store.
  Future<Map<String, Set<String>>> get listKeyedRepositories;

  /// Checks whether the store has any unsaved changes.
  Future<bool> get hasUnsavedChanges;

  /// Checks whether the store is closed.
  bool get isClosed;

  /// Closes the database.
  Future<void> close();

  /// Gets the [NitriteConfig] instance to configure the database.
  NitriteConfig get config;

  /// Gets the [NitriteStore] instance powering the database.
  NitriteStore<T> getStore<T extends StoreConfig>();

  /// Gets database meta data.
  Future<StoreMetaData> get databaseMetaData;

  /// Creates a [Session] for transaction.
  Session createSession();

  /// Checks whether a particular [NitriteCollection] exists in the store.
  Future<bool> hasCollection(String name) async {
    checkOpened();
    var collections = await listCollectionNames;
    return collections.contains(name);
  }

  /// Checks whether a particular [ObjectRepository] exists in the store.
  Future<bool> hasRepository<T>(
      {EntityDecorator<T>? entityDecorator, String? key}) async {
    checkOpened();
    var nitriteMapper = config.nitriteMapper;
    var entityName = entityDecorator == null
        ? getEntityName<T>(nitriteMapper)
        : entityDecorator.entityName;

    if (key.isNullOrEmpty) {
      var repos = await listRepositories;
      return repos.contains(entityName);
    } else {
      var repos = await listKeyedRepositories;
      return repos.containsKey(key) && repos[key]?.contains(entityName) != null;
    }
  }

  /// Validate the collection name.
  void validateCollectionName(String name) {
    name.notNullOrEmpty("name cannot be null or empty");

    for (String reservedName in reservedNames) {
      if (name.contains(reservedName)) {
        throw ValidationException("name cannot contain $reservedName");
      }
    }
  }

  /// Checks if the store is opened.
  void checkOpened() {
    if (getStore().isClosed) {
      throw NitriteIOException("Nitrite is closed");
    }
  }
}
