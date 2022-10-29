import 'package:analyzer/dart/element/element.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_entity_generator/src/common.dart';
import 'package:nitrite_entity_generator/src/extensions.dart';
import 'package:nitrite_entity_generator/src/parser.dart';
import 'package:nitrite_entity_generator/src/type_checker.dart';
import 'package:source_gen/source_gen.dart';

class IdFieldParser implements Parser<EntityId> {
  final FieldElement _fieldElement;

  IdFieldParser(this._fieldElement);

  @override
  EntityId parse() {
    var idFieldName = _getIdFieldName();
    var embeddedFields = _getEmbeddedFields();

    var type = _fieldElement.type;
    if (isBuiltin(type)) {
      if (embeddedFields.isNotEmpty) {
        throw InvalidGenerationSourceError(
            'Id field of build-in type cannot be embedded',
            element: _fieldElement);
      }

      return EntityId(
        idFieldName,
      );
    } else {
      var typeElement = type.element2;
      if (typeElement is! ClassElement) {
        throw InvalidGenerationSourceError(
          'Invalid type found for `@Id`',
          element: _fieldElement,
        );
      }

      if (embeddedFields.isEmpty) {
        throw InvalidGenerationSourceError(
          'Id field of class type must be embedded',
          element: _fieldElement,
        );
      }

      return EntityId(
        idFieldName,
        embeddedFields,
      );
    }
  }

  String _getIdFieldName() {
    return _fieldElement
            .getAnnotation(Id)
            ?.getField(IdField.fieldName)
            ?.toStringValue() ??
        _fieldElement.name;
  }

  List<String> _getEmbeddedFields() {
    return _fieldElement
            .getAnnotation(Id)
            ?.getField(IdField.embeddedFields)
            ?.toListValue()
            ?.mapNotNull((field) => field.toStringValue())
            .toList() ??
        [];
  }
}
