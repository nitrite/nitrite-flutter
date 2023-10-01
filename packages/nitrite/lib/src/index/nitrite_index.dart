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
      List<dynamic>? nitriteIds, FieldValues fieldValues) {
    nitriteIds = nitriteIds ?? <NitriteId>[];

    if (isUnique && nitriteIds.length == 1) {
      // if key is already exists for unique type, throw error
      throw UniqueConstraintException(
          'Unique key constraint violation for ${fieldValues.fields}');
    }

    // index always are in ascending format
    nitriteIds.add(fieldValues.nitriteId!);
    return nitriteIds;
  }

  /// Removes the [NitriteId] of the [FieldValues] from the existing indexed
  /// list of [NitriteId]s.
  List<dynamic> removeNitriteIds(
      List<dynamic> nitriteIds, FieldValues fieldValues) {
    nitriteIds.remove(fieldValues.nitriteId!);
    return nitriteIds;
  }
}
