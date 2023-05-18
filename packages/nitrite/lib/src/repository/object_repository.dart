import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/persistent_collection.dart';

/// Represents a type-safe persistent dart object collection. An object
/// repository is backed by a [NitriteCollection], where all objects are
/// converted into a [Document] and saved into the database.
///
/// An object repository is observable like its underlying [NitriteCollection].
///
/// **Create a repository**
///
/// ```dart
/// // create/open a database
/// var db = Nitrite().builder()
///    .openOrCreate("user", "password");
///
/// // create a repository
/// var repository = db.getRepository<Employee>();
///
/// // insert an object into the repository
/// var employee = Employee(name: "John Doe");
/// repository.insert(employee);
/// ```
abstract class ObjectRepository<T> extends PersistentCollection<T> {
  /// Inserts an object into this repository. If the object contains a value
  /// with an id, then the value will be used as a unique key to identify
  /// the object in the repository.
  ///
  /// If any of the fields is already indexed in the repository, then after
  /// insertion the index will also be updated.
  ///
  /// **NOTE**: This operations will notify all [CollectionEventListener]
  /// instances registered to this repository with change type
  /// [EventType.insert].
  Future<WriteResult> insert(T element) {
    return insertMany([element]);
  }

  /// Inserts objects into this repository. If the objects contains a value
  /// with an id, then the value will be used as a unique key to identify
  /// the object in the repository.
  ///
  /// If any of the fields is already indexed in the repository, then after
  /// insertion the index will also be updated.
  ///
  /// **NOTE**: This operations will notify all [CollectionEventListener]
  /// instances registered to this repository with change type
  /// [EventType.insert].
  Future<WriteResult> insertMany(List<T> elements);

  /// Update a single object in the repository. If [insertIfAbsent] is true,
  /// then this operation will insert the object if it does not exist in the
  /// repository.
  ///
  /// If any object does not contain any id value and [insertIfAbsent]
  /// is false, then nitrite throws an exception.
  ///
  /// **NOTE**: This operations will notify all [CollectionEventListener]
  /// instances registered to this repository with change type
  /// [EventType.update].
  Future<WriteResult> updateOne(T element, {bool insertIfAbsent = false});

  /// Update the filtered objects in the repository with the [update] object.
  ///
  /// If the [filter] is [all], it will update all objects in the collection.
  ///
  /// **NOTE**: This operations will notify all [CollectionEventListener]
  /// instances registered to this repository with change type
  /// [EventType.update].
  Future<WriteResult> update(Filter filter, T element,
      [UpdateOptions? updateOptions]);

  /// Update the filtered objects in the repository with the [update] document.
  ///
  /// If the [filter] is [all], it will update all objects in the collection.
  ///
  /// **NOTE**: This operations will notify all [CollectionEventListener]
  /// instances registered to this repository with change type
  /// [EventType.update].
  Future<WriteResult> updateDocument(Filter filter, Document document,
      {bool justOnce = false});

  /// Removes the element from the repository.
  ///
  /// **NOTE**: This operations will notify all [CollectionEventListener]
  /// instances registered to this collection with change type
  /// [EventType.remove].
  Future<WriteResult> removeOne(T element);

  /// Removes matching elements from the repository.
  ///
  /// If the [filter] is [all], it will remove all objects from the repository.
  ///
  /// **NOTE**: This operations will notify all [CollectionEventListener]
  /// instances registered to this repository with change type
  /// [EventType.remove].
  Future<WriteResult> remove(Filter filter, {bool justOne = false});

  /// Applies a filter on the repository and returns a customized cursor to the
  /// selected objects.
  ///
  /// **NOTE**: If there is an index on the value specified in the filter,
  /// this operation will take advantage of the index.
  Future<Cursor<T>> find({Filter? filter, FindOptions? findOptions});

  /// Gets a single element from the repository by its id. If no element
  /// is found, it will return `Future<null>`.
  Future<T?> getById<I>(I id);

  /// Returns the type associated with this repository.
  Type getType();

  /// Returns the underlying [NitriteCollection] instance.
  NitriteCollection get documentCollection;
}
