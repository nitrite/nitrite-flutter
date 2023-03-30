import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/validation_utils.dart';

abstract class NitriteIndex {
  IndexDescriptor get indexDescriptor;

  Future<void> write(FieldValues fieldValues);

  Future<void> remove(FieldValues fieldValues);

  Future<void> drop();

  Stream<NitriteId> findNitriteIds(FindPlan findPlan);

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

  /// Adds a [NitriteId] of the [FieldValues] to the existing indexed
  /// list of [NitriteId]s.
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

  /// Removes a [NitriteId] of the [FieldValues] from the existing indexed
  /// list of [NitriteId]s.
  List<dynamic> removeNitriteIds(
      List<dynamic> nitriteIds, FieldValues fieldValues) {
    nitriteIds.remove(fieldValues.nitriteId!);
    return nitriteIds;
  }
}
