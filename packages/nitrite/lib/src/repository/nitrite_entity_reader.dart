import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/async/executor.dart';
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
      var requiredIndex = _objectIdField != null &&
          _objectIdField!.embeddedFieldNames.isNotEmpty;

      var hasIndex = requiredIndex &&
          await _nitriteCollection.hasIndex(_objectIdField!.embeddedFieldNames);

      if (!hasIndex && requiredIndex) {
        await _nitriteCollection
            .createIndex(_objectIdField!.embeddedFieldNames);
      }
    }

    if (entity.entityIndexes != null) {
      var indexes = entity.entityIndexes;

      if (indexes != null) {
        var executor = Executor();
        for (var index in indexes) {
          var hasIndex = await _nitriteCollection.hasIndex(index.fieldNames);
          if (!hasIndex) {
            executor.submit(() async => await _nitriteCollection.createIndex(
                index.fieldNames, indexOptions(index.indexType)));
          }
        }

        await executor.execute();
      }
    }
  }
}
