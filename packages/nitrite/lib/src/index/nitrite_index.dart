import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

/// The NitriteIndex interface represents an index in Nitrite database.
/// It provides methods to write, remove and find NitriteIds from the index.
/// It also provides methods to drop the index and validate the index field.
abstract class NitriteIndex {
  /// Gets index descriptor.
  IndexDescriptor get indexDescriptor;

  /// Writes the given field values to the index.
  Future<void> write(FieldValues fieldValues);

  /// Removes the index entry for the specified field values.
  Future<void> remove(FieldValues fieldValues);

  /// Drops the index.
  Future<void> drop();

  /// Finds the NitriteIds from the index for the given find plan.
  Stream<NitriteId> findNitriteIds(FindPlan findPlan);

  /// Reads every `(indexed value, id)` pair out of the index, so a sorted query
  /// can decide its order without deserializing a single document.
  ///
  /// Returns the pairs in no particular order, or `null` when the index is not
  /// a faithful stand-in for the collection of [collectionSize] documents - a
  /// document that contributes several index entries (a multi-valued field is
  /// indexed once per element) or none at all (a non-comparable value is not
  /// indexed) makes the index unusable for ordering, and the caller must sort
  /// the documents instead.
  Future<List<(DBValue, NitriteId)>?> readSortKeys(int collectionSize) async =>
      null;

  /// Checks if the index is unique.
  bool get isUnique => indexDescriptor.indexType == IndexType.unique;

  /// Validates the index field.
  void validateIndexField(dynamic value, String field) {
    if (value == null) return;
    if (value is Iterable) {
      validateIterableIndexField(value, field);
    } else if (value is! Comparable) {
      throw ValidationException('Index field $field must be a comparable type');
    }
  }

  /// Adds the given [NitriteId]s to the index for the given field values.
  List<dynamic> addNitriteIds(
    List<dynamic>? nitriteIds,
    FieldValues fieldValues,
  ) {
    nitriteIds = nitriteIds ?? <NitriteId>[];

    if (isUnique && nitriteIds.isNotEmpty) {
      // Another document already holding this key is the violation. The same
      // document again is not: a unique index over an array field visits a
      // repeated element once per occurrence, and a rebuild or a replayed write
      // reaches the key the document already owns.
      if (nitriteIds.any((id) => id != fieldValues.nitriteId)) {
        throw UniqueConstraintException(
          'Unique key constraint violation for ${fieldValues.fields}',
        );
      }
      return nitriteIds;
    }

    // index always are in ascending format
    nitriteIds.add(fieldValues.nitriteId!);
    return nitriteIds;
  }

  /// Removes the [NitriteId] of the [FieldValues] from the existing indexed
  /// list of [NitriteId]s.
  List<dynamic> removeNitriteIds(
    List<dynamic> nitriteIds,
    FieldValues fieldValues,
  ) {
    nitriteIds.remove(fieldValues.nitriteId!);
    return nitriteIds;
  }
}
