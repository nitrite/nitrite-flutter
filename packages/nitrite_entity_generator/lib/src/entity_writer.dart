import 'package:code_builder/code_builder.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_entity_generator/src/common.dart';

class EntityWriter {
  final EntityInfo _entityInfo;

  EntityWriter(this._entityInfo);

  Mixin write() {
    return Mixin((builder) {
      builder
        ..name = '_\$${_entityInfo.className}EntityMixin'
        ..implements.add(refer('NitriteEntity'))
        ..methods.add(_generateEntityName())
        ..methods.add(_generateEntityIndices())
        ..methods.add(_generateEntityId());
    });
  }

  Method _generateEntityName() {
    return Method((builder) {
      builder
        ..name = 'entityName'
        ..annotations.add(refer('override'))
        ..type = MethodType.getter
        ..lambda = true
        ..returns = refer('String')
        ..body = Code('"${_entityInfo.entityName}"');
    });
  }

  Method _generateEntityIndices() {
    return Method((builder) {
      builder
        ..name = 'entityIndexes'
        ..returns = refer('List<EntityIndex>')
        ..annotations.add(refer('override'))
        ..type = MethodType.getter
        ..lambda = true;

      if (_entityInfo.entityIndices.isEmpty) {
        builder.body = Code('const []');
      } else {
        StringBuffer buffer = StringBuffer();
        for (var index in _entityInfo.entityIndices) {
          buffer.write('EntityIndex([');
          buffer.write(index.fieldNames.map((field) => '"$field"').join(', '));
          buffer.write('], ');
          switch (index.indexType) {
            case IndexType.unique:
              buffer.write('IndexType.unique)');
              break;
            case IndexType.nonUnique:
              buffer.write('IndexType.nonUnique)');
              break;
            case IndexType.fullText:
              buffer.write('IndexType.fullText)');
              break;
            default:
              buffer.write(index.indexType.toString());
              break;
          }
          buffer.writeln(',');
        }

        builder.body = Code('''
          const [
            ${buffer.toString()}
          ]
        ''');
      }
    });
  }

  Method _generateEntityId() {
    return Method((builder) {
      builder
        ..name = 'entityId'
        ..annotations.add(refer('override'))
        ..type = MethodType.getter
        ..lambda = true;

      if (_entityInfo.entityId == null) {
        builder
          ..returns = refer('EntityId?')
          ..body = Code('null');
      } else {
        builder.returns = refer('EntityId');

        var isNitriteId = _entityInfo.entityId!.isNitriteId;
        if (_entityInfo.entityId!.subFields.isEmpty) {
          builder.body = Code(
              'EntityId("${_entityInfo.entityId!.fieldName}", $isNitriteId)');
        } else {
          builder.body = Code('''
            EntityId(
              "${_entityInfo.entityId!.fieldName}",
              $isNitriteId,
              [${_entityInfo.entityId!.subFields.map((field) => '"$field"').join(', ')}],
            )
          ''');
        }
      }
    });
  }
}
