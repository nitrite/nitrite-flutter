import 'package:analyzer/dart/element/element.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_entity_generator/src/common.dart';
import 'package:nitrite_entity_generator/src/extensions.dart';
import 'package:nitrite_entity_generator/src/id_field_parser.dart';
import 'package:nitrite_entity_generator/src/parser.dart';
import 'package:nitrite_entity_generator/src/type_checker.dart';
import 'package:source_gen/source_gen.dart';

class EntityParser extends Parser<EntityInfo> {
  final ClassElement _classElement;

  EntityParser(this._classElement);

  @override
  EntityInfo parse() {
    _validateEntity();

    var entityInfo = EntityInfo(_classElement.displayName);
    entityInfo.entityName = _getEntityName();
    entityInfo.entityIndices = _getEntityIndices();
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

    // check mappable
    if (!isMappable.isAssignableFromType(_classElement.thisType)) {
      throw InvalidGenerationSourceError(
        '`@Entity` can only be used on classes that implement `Mappable`.',
        element: _classElement,
      );
    }

    // check for default constructor
    var constructors = _classElement.constructors;
    for (var ctor in constructors) {
      var parameters = ctor.parameters;
      for (var param in parameters) {
        if (!param.isOptional) {
          throw InvalidGenerationSourceError(
            '`@Entity` can only be used on classes with a default constructor.',
            element: _classElement,
          );
        }
      }
    }
  }

  List<EntityIndex> _getEntityIndices() {
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

  EntityId? _getEntityId() {
    final fields = [
      ..._classElement.fields,
      ..._classElement.allSupertypes.expand((type) => type.element.fields),
    ];

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
}