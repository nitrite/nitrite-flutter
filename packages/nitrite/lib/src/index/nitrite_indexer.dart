import 'package:nitrite/nitrite.dart';

/// Represents an indexer for creating a nitrite index.
abstract class NitriteIndexer extends NitritePlugin {
  /// Gets the index type.
  String get indexType;

  /// Validates an index on the fields.
  Future<void> validateIndex(Fields fields);

  /// Drops the index specified by the index descriptor.
  Future<void> dropIndex(
      IndexDescriptor indexDescriptor, NitriteConfig nitriteConfig);

  /// Writes an index entry.
  Future<void> writeIndexEntry(FieldValues fieldValues,
      IndexDescriptor indexDescriptor, NitriteConfig nitriteConfig);

  /// Removes an index entry.
  Future<void> removeIndexEntry(FieldValues fieldValues,
      IndexDescriptor indexDescriptor, NitriteConfig nitriteConfig);

  /// Finds a list of [NitriteId] after executing the [FindPlan] on the index.
  Stream<NitriteId> findByFilter(
      FindPlan findPlan, NitriteConfig nitriteConfig);
}
