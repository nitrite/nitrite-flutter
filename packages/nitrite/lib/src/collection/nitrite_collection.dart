import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/persistent_collection.dart';

/// Represents a named document collection stored in nitrite database.
/// It persists documents into the database. Each document is associated
/// with a unique [NitriteId] in a collection.
///
/// A nitrite collection supports indexing. Every nitrite collection is also
/// observable.
///
/// **Create a collection**
///
/// ```dart
/// var db = Nitrite().builder()
///    .openOrCreate("user", "password");
///
/// var collection = db.getCollection("products");
/// ```
abstract class NitriteCollection extends PersistentCollection<Document> {
  /// Insert documents into a collection. If the document contains a `_id` value,
  /// then the value will be used as a unique key to identify the document in
  /// the collection.
  /// If the document does not contain any `_id` value, then nitrite will
  /// generate a new [NitriteId] and will add it to the document.
  ///
  /// If any of the value is already indexed in the collection, then after
  /// insertion the index will also be updated.
  ///
  /// **NOTE**: These operations will notify all [CollectionEventListener]
  /// instances registered to this collection with change type
  /// [EventType.insert].
  Future<WriteResult> insert(List<Document> documents);

  /// Update a single document in the collection. If [insertIfAbsent] is true,
  /// then this operation will insert the document if it does not exist in the
  /// collection.
  ///
  /// If the document does not contain any `_id` value and [insertIfAbsent]
  /// is false, then nitrite throws an exception.
  ///
  /// **NOTE**: This operations will notify all [CollectionEventListener]
  /// instances registered to this collection with change type
  /// [EventType.update].
  Future<WriteResult> updateOne(Document document,
      [bool insertIfAbsent = false]);

  /// Update the filtered elements in the collection with the [update].
  ///
  /// If the [filter] is [all], it will update all documents in the collection.
  ///
  /// **NOTE**: This operations will notify all [CollectionEventListener]
  /// instances registered to this collection with change type
  /// [EventType.update].
  Future<WriteResult> update(Filter filter, Document update,
      [UpdateOptions? updateOptions]);

  /// Removes matching elements from the collection.
  ///
  /// If the [filter] is [all], it will remove all documents from the collection.
  ///
  /// **NOTE**: This operations will notify all [CollectionEventListener]
  /// instances registered to this collection with change type
  /// [EventType.remove].
  Future<WriteResult> remove(Filter filter, [bool justOne = false]);

  /// Removes the document from the collection.
  ///
  /// **NOTE**: This operations will notify all [CollectionEventListener]
  /// instances registered to this collection with change type
  /// [EventType.remove].
  Future<WriteResult> removeOne(Document document);

  /// Applies a filter on the collection and returns a customized cursor to the
  /// selected documents.
  ///
  /// **NOTE**: If there is an index on the value specified in the filter,
  /// this operation will take advantage of the index.
  Future<DocumentCursor> find([Filter? filter, FindOptions? findOptions]);

  /// Gets a single element from the collection by its id. If no element
  /// is found, it will return `Future<null>`.
  Future<Document?> getById(NitriteId id);

  /// Returns the name of the [NitriteCollection].
  String get name;
}
