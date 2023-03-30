import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';

class NitriteEntityReader<T> {
  final NitriteMapper _nitriteMapper;
  final NitriteCollection _nitriteCollection;

  EntityId? _objectIdField;

  NitriteEntityReader(this._nitriteMapper, this._nitriteCollection);

  EntityId? get objectIdField => _objectIdField;

  Future<void> readAndExecute() async {
    var entity = newInstance<T>(_nitriteMapper) as NitriteEntity;

    if (entity.entityId != null) {
      _objectIdField = entity.entityId;

      var idFieldNames = _objectIdField!.isEmbedded
          ? _objectIdField!.embeddedFieldNames
          : [_objectIdField!.fieldName];

      var hasIndex = await _nitriteCollection.hasIndex(idFieldNames);

      if (!hasIndex) {
        await _nitriteCollection.createIndex(
            idFieldNames, indexOptions(IndexType.unique));
      }
    }

    if (entity.entityIndexes != null) {
      var indexes = entity.entityIndexes;

      if (indexes != null) {
        for (var index in indexes) {
          var hasIndex = await _nitriteCollection.hasIndex(index.fieldNames);
          if (!hasIndex) {
            await _nitriteCollection.createIndex(
                index.fieldNames, indexOptions(index.indexType));
          }
        }
      }
    }
  }
}
