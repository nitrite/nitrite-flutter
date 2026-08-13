import 'package:nitrite/nitrite.dart';

/// An abstract class representing a Nitrite indexer plugin.
///
/// NitriteIndexer extends NitritePlugin and provides a base class for all Nitrite
/// indexer plugins. It defines the basic structure and functionality of an indexer
/// plugin that can be used to index Nitrite collections.
abstract class NitriteIndexer extends NitritePlugin {
  /// Gets the index type.
  String get indexType;

  /// Validates the given fields for indexing.
  Future<void> validateIndex(Fields fields);

  /// Drops the index from the collection.
  Future<void> dropIndex(
    IndexDescriptor indexDescriptor,
    NitriteConfig nitriteConfig,
  );

  /// Writes an index entry for the given field values and index descriptor.
  Future<void> writeIndexEntry(
    FieldValues fieldValues,
    IndexDescriptor indexDescriptor,
    NitriteConfig nitriteConfig,
  );

  /// Removes an index entry for the given field values and index descriptor
  /// from the Nitrite database.
  Future<void> removeIndexEntry(
    FieldValues fieldValues,
    IndexDescriptor indexDescriptor,
    NitriteConfig nitriteConfig,
  );

  /// Finds the NitriteIds of the documents that match the given filter in
  /// the specified collection.
  Stream<NitriteId> findByFilter(
    FindPlan findPlan,
    NitriteConfig nitriteConfig,
  );

  /// Reads every `(indexed value, id)` pair out of the given index, so a sorted
  /// query can decide its order without deserializing a single document.
  ///
  /// Returns `null` when this indexer cannot supply them, or when the index is
  /// not a faithful stand-in for the collection of [collectionSize] documents.
  Future<List<(DBValue, NitriteId)>?> readSortKeys(
    IndexDescriptor indexDescriptor,
    NitriteConfig nitriteConfig,
    int collectionSize,
  ) async =>
      null;
}
