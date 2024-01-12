import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

/// Nitrite is a lightweight, embedded, and self-contained NoSQL database.
/// It provides an easy-to-use API to store and retrieve data. Nitrite stores
/// data in the form of documents and supports indexing on fields within
/// the documents to provide efficient search capabilities. Nitrite supports
/// transactions, and provides a simple and efficient way to persist data.
///
/// Nitrite is designed to be embedded within the application
/// and does not require any external setup or installation.
abstract class Nitrite {
  /// Returns a new instance of [NitriteBuilder] to build a new
  /// Nitrite database instance.
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
  /// is already opened, it is returned as is.
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
  Future<ObjectRepository<T>> getRepository<T>(
      {EntityDecorator<T>? entityDecorator, String? key});

  /// Destroys a [NitriteCollection] without opening it first.
  Future<void> destroyCollection(String name);

  /// Destroys an [ObjectRepository] without opening it first.
  Future<void> destroyRepository<T>(
      {EntityDecorator<T>? entityDecorator, String? key});

  /// Gets the set of all [NitriteCollection]s' names saved in the store.
  Future<Set<String>> get listCollectionNames;

  /// Gets the set of all class names corresponding to all [ObjectRepository]s
  /// in the store.
  Future<Set<String>> get listRepositories;

  /// Gets the map of all key to the class names corresponding
  /// to all keyed-[ObjectRepository]s in the store.
  Future<Map<String, Set<String>>> get listKeyedRepositories;

  /// Checks if there are any unsaved changes in the Nitrite database.
  Future<bool> get hasUnsavedChanges;

  /// Checks if the Nitrite database instance is closed.
  bool get isClosed;

  /// Closes the database.
  Future<void> close();

  /// Gets the [NitriteConfig] instance to configure the database.
  NitriteConfig get config;

  /// Gets the [NitriteStore] instance associated with this Nitrite database.
  NitriteStore<T> getStore<T extends StoreConfig>();

  /// Returns the metadata of the database store.
  Future<StoreMetaData> get databaseMetaData;

  /// Creates a new session for the Nitrite database. A session is a lightweight
  /// container that holds transactions. Multiple sessions can be created for a
  /// single Nitrite database instance.
  Session createSession();

  /// Checks if a collection with the given name exists in the database.
  Future<bool> hasCollection(String name) async {
    checkOpened();
    var collections = await listCollectionNames;
    return collections.contains(name);
  }

  /// Checks if a repository of the specified type and key exists in the
  /// database.
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

  /// Validates the given collection name.
  /// Throws [ValidationException] if the name is invalid.
  void validateCollectionName(String name) {
    name.notNullOrEmpty("name cannot be null or empty");

    for (String reservedName in reservedNames) {
      if (name.contains(reservedName)) {
        throw ValidationException("name cannot contain $reservedName");
      }
    }
  }

  /// Checks if the Nitrite database is opened or not.
  /// Throws [NitriteIOException] if the database is closed.
  void checkOpened() {
    if (getStore().isClosed) {
      throw NitriteIOException("Nitrite is closed");
    }
  }
}
