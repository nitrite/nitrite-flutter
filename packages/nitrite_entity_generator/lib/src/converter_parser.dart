import 'package:analyzer/dart/element/element.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_entity_generator/src/common.dart';
import 'package:nitrite_entity_generator/src/extensions.dart';
import 'package:nitrite_entity_generator/src/parser.dart';
import 'package:source_gen/source_gen.dart';

class ConverterParser extends Parser<ConverterInfo> {
  final ClassElement _classElement;

  ConverterParser(this._classElement);

  @override
  ConverterInfo parse() {
    _validateClass();

    var converterName = _getConverterName();
    var className = _classElement.displayName;
    var fieldInfoList = _getFieldInfoList();
    return ConverterInfo(className, converterName, fieldInfoList);
  }

  void _validateClass() {
    // check mixin
    if (_classElement.mixins.isNotEmpty) {
      throw InvalidGenerationSourceError(
        '`@Converter` can not be used with mixins.',
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
            '`@Converter` can only be used on classes with a default constructor.',
            element: _classElement,
          );
        }
      }
    }
  }

  String _getConverterName() {
    var converterName = _classElement
        .getAnnotation(Converter)
        ?.getField(ConverterField.className)
        ?.toStringValue();

    if (converterName == null || converterName.isEmpty) {
      return _classElement.displayName + 'Converter';
    } else {
      return converterName;
    }
  }

  List<FieldInfo> _getFieldInfoList() {
    var fieldInfoList = <FieldInfo>[];
    var fieldElements = _classElement.fields;
    for (var element in fieldElements) {
      if (_isValidField(element)) {
        var property = element.getAnnotation(Property);
        var aliasName =
            property?.getField(PropertyField.alias)?.toStringValue();
        aliasName ??= "";

        var fieldName = element.displayName;

        var fieldType = element.type;
        fieldInfoList.add(FieldInfo(fieldName, fieldType, aliasName));
      }
    }
    return fieldInfoList;
  }

  bool _isValidField(FieldElement element) {
    var ignored = element.getAnnotation(IgnoredProperty);
    if (ignored != null) {
      return false;
    }

    var property = element.getAnnotation(Property);
    if (property != null &&
        (element.isFinal ||
            element.isStatic ||
            element.isPrivate ||
            element.isSynthetic)) {
      throw InvalidGenerationSourceError(
        '`@Property` cannot be used on a private/final/static/synthetic field.',
        element: element,
      );
    }

    if (element.isStatic) return false;
    if (element.isFinal) return false;
    if (element.isPrivate) return false;
    if (element.isSynthetic) return false;
    return true;
  }
}
