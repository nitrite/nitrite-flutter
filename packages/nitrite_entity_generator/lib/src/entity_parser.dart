import 'package:analyzer/dart/element/element.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_entity_generator/src/common.dart';
import 'package:nitrite_entity_generator/src/extensions.dart';
import 'package:nitrite_entity_generator/src/id_field_parser.dart';
import 'package:nitrite_entity_generator/src/parser.dart';
import 'package:source_gen/source_gen.dart';

class EntityParser extends Parser<EntityInfo> {
  final ClassElement _classElement;

  EntityParser(this._classElement);

  @override
  EntityInfo parse() {
    // validate entity type
    _validateEntity();

    var entityInfo = EntityInfo(_classElement.displayName);

    // get entity name
    entityInfo.entityName = _getEntityName();

    // get indices info from @Entity and @Index annotations
    entityInfo.entityIndices = _getEntityIndices();

    // get entity id from @Id annotation
    entityInfo.entityId = _getEntityId();
    return entityInfo;
  }

  String _getEntityName() {
    var entityName = _classElement
        .getAnnotation(Entity)
        ?.getField(EntityField.entityName)
        ?.toStringValue();

    if (entityName == null || entityName.isEmpty) {
      return _classElement.displayName;
    } else {
      return entityName;
    }
  }

  void _validateEntity() {
    // check mixin
    if (_classElement.mixins.isNotEmpty) {
      throw InvalidGenerationSourceError(
        '`@Entity` can not be used with mixins.',
        element: _classElement,
      );
    }

    // check for default constructor
    // var constructors = _classElement.constructors;
    // for (var ctor in constructors) {
    //   var parameters = ctor.parameters;
    //   for (var param in parameters) {
    //     if (!param.isOptional) {
    //       throw InvalidGenerationSourceError(
    //         '`@Entity` can only be used on classes with a default constructor.',
    //         element: _classElement,
    //       );
    //     }
    //   }
    // }
  }

  EntityId? _getEntityId() {
    final fields = [
      ..._classElement.fields,
      ..._classElement.allSupertypes.expand((type) => type.element.fields),
    ];

    // field should not be static or synthetic and must be annotated with @Id
    var idFields = fields
        .where((fieldElement) => fieldElement.shouldBeIncluded())
        .where((fieldElement) => fieldElement.hasAnnotation(Id));

    if (idFields.isEmpty) {
      return null;
    }

    if (idFields.length > 1) {
      throw InvalidGenerationSourceError(
        '`@Id` can only be used once per class.',
        element: _classElement,
      );
    }

    return IdFieldParser(idFields.first).parse();
  }

  List<EntityIndex> _getEntityIndices() {
    var indices = <EntityIndex>{};

    // get from @Entity annotations
    indices.addAll(_getEntityIndexes());

    // get from @Index annotations
    indices.addAll(_getIndexes());

    return indices.toList();
  }

  List<EntityIndex> _getEntityIndexes() {
    return _classElement
            .getAnnotation(Entity)
            ?.getField(EntityField.entityIndices)
            ?.toListValue()
            ?.map((indexObject) {
          final indexFieldNames = indexObject
              .getField(IndexField.fields)
              ?.toListValue()
              ?.mapNotNull((field) => field.toStringValue())
              .toList();

          if (indexFieldNames == null || indexFieldNames.isEmpty) {
            throw InvalidGenerationSourceError(
              '`Index` must have at least one field.',
              element: _classElement,
            );
          }

          var indexType =
              indexObject.getField(IndexField.type)?.toStringValue() ??
                  IndexType.unique;
          return EntityIndex(indexFieldNames, indexType);
        }).toList() ??
        [];
  }

  List<EntityIndex> _getIndexes() {
    var indexes = <EntityIndex>[];
    // use recursion to scan through the hierarchy
    var scanner = _IndexScanner(_classElement);
    indexes.addAll(scanner.getIndexes());
    return indexes;
  }
}

// @Index annotation scanner
class _IndexScanner {
  final ClassElement _classElement;

  _IndexScanner(this._classElement);

  List<EntityIndex> getIndexes() {
    var indexes = <EntityIndex>[];
    var fields = _classElement
        .getAnnotation(Index)
        ?.getField(IndexField.fields)
        ?.toListValue()
        ?.mapNotNull((field) => field.toStringValue())
        .toList();

    if (fields != null && fields.isNotEmpty) {
      var type = _classElement
          .getAnnotation(Index)
          ?.getField(IndexField.type)
          ?.toStringValue();

      indexes.add(EntityIndex(fields, type ?? IndexType.unique));
    }

    // get index details from all super classes
    var superTypes = _classElement.allSupertypes;
    superTypes.forEach((type) {
      var scanner = _IndexScanner(type.element as ClassElement);
      indexes.addAll(scanner.getIndexes());
    });

    return indexes.toList();
  }
}
