import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';

/// @nodoc
class NitriteEntityReader<T> {
  final NitriteMapper _nitriteMapper;
  final NitriteCollection _nitriteCollection;

  EntityId? _objectIdField;

  NitriteEntityReader(this._nitriteMapper, this._nitriteCollection);

  EntityId? get objectIdField => _objectIdField;

  void performScan() {
    var entity = newInstance<T>(_nitriteMapper) as NitriteEntity;

    if (entity.entityId != null) {
      _objectIdField = entity.entityId;
    }
  }

  Future<void> createIdIndex() async {
    var entity = newInstance<T>(_nitriteMapper) as NitriteEntity;

    if (entity.entityId != null) {
      var idFieldNames = entity.entityId!.isEmbedded
          ? entity.entityId!.encodedFieldNames
          : [entity.entityId!.fieldName];
      await _nitriteCollection.createIndex(
          idFieldNames, indexOptions(IndexType.unique));
    }
  }

  Future<void> createIndices() async {
    var entity = newInstance<T>(_nitriteMapper) as NitriteEntity;

    if (entity.entityIndexes != null) {
      var indexes = entity.entityIndexes;

      if (indexes != null) {
        for (var index in indexes) {
          await _nitriteCollection.createIndex(
              index.fieldNames, indexOptions(index.indexType));
        }
      }
    }
  }
}
