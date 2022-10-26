import 'package:analyzer/dart/element/element.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_entity_generator/src/common.dart';
import 'package:nitrite_entity_generator/src/extensions.dart';
import 'package:nitrite_entity_generator/src/parser.dart';
import 'package:source_gen/source_gen.dart';
import 'package:collection/collection.dart';

class ConverterParser extends Parser<ConverterInfo> {
  final ClassElement _classElement;

  ConverterParser(this._classElement);

  @override
  ConverterInfo parse() {
    var className = _getClassName();
    var converterName = _getConverterName();
    var ctorInfo = _getConstructorInfo();
    var fieldInfoList = _getFieldInfoList();
    var propertyInfoList = _getPropertyInfoList();

    _validateConverter(ctorInfo, propertyInfoList, fieldInfoList);

    return ConverterInfo(
        className, converterName, fieldInfoList, propertyInfoList, ctorInfo);
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

  bool _isValidField(FieldElement element) {
    var ignored = element.getAnnotation(IgnoredProperty);
    if (ignored != null) {
      return false;
    }

    var property = element.getAnnotation(Property);
    if (property != null &&
        (element.isStatic || element.isPrivate || element.isSynthetic)) {
      throw InvalidGenerationSourceError(
        '`@Property` cannot be used on a private/static/synthetic field.',
        element: element,
      );
    }

    if (element.isStatic) return false;
    if (element.isPrivate) return false;
    if (element.isSynthetic) return false;
    return true;
  }

  String _getClassName() {
    // check mixin
    if (_classElement.mixins.isNotEmpty) {
      throw InvalidGenerationSourceError(
        '`@Converter` can not be used with mixins.',
        element: _classElement,
      );
    }

    if (_classElement.isAbstract) {
      throw InvalidGenerationSourceError(
        '`@Converter` can not be used on abstract class.',
        element: _classElement,
      );
    }

    return _classElement.displayName;
  }

  ConstructorInfo _getConstructorInfo() {
    // check for valid constructors
    // 1. default ctor
    // 2. ctor with all positional optional parameters
    //    2.1 all fields has to be non-final, otherwise those can not
    //        be set in ctor with positional optional parameters
    // 3. ctor with all named optional parameters
    //    3.1 all fields either has to be final or all non-final, no
    //        mix-and-match is allowed.
    //    3.2 all field names in the class must match with ctor parameters
    // 4. check for getter and setters properties

    var constructors = _classElement.constructors;
    var validConstructors = constructors.where((ctor) =>
        ctor.isPublic &&
        ctor.name.isEmpty &&
        (ctor.isGenerative || !ctor.isFactory || ctor.isDefaultConstructor));

    if (validConstructors.isEmpty) {
      throw InvalidGenerationSourceError(
        '`@Converter` can only be used on classes which has at least one public '
        'constructor which is either a default constructor or one with all '
        'optional parameters.',
        element: _classElement,
      );
    }

    bool hasDefaultCtor =
        validConstructors.any((ctor) => ctor.parameters.length == 0);

    bool hasAllOptionalPositionalCtor = validConstructors.any((ctor) =>
        ctor.parameters.isNotEmpty &&
        ctor.parameters.every((param) => param.isOptionalPositional));

    bool hasAllOptionalNamedCtor = validConstructors.any((ctor) =>
        ctor.parameters.isNotEmpty &&
        ctor.parameters.every((param) => param.isOptionalNamed));

    var ctorParamNames = <String>[];
    for (var ctor in validConstructors) {
      var names = ctor.parameters.map((e) => e.displayName).toList();
      if (names.length > ctorParamNames.length) {
        ctorParamNames = names;
      }
    }

    return ConstructorInfo(
        hasDefaultCtor: hasDefaultCtor,
        hasAllOptionalNamedCtor: hasAllOptionalNamedCtor,
        hasAllOptionalPositionalCtor: hasAllOptionalPositionalCtor,
        ctorParamNames: ctorParamNames);
  }

  List<FieldInfo> _getFieldInfoList() {
    var fieldInfos = <FieldInfo>[];
    var fieldElements = _classElement.fields;
    for (var element in fieldElements) {
      if (_isValidField(element)) {
        var property = element.getAnnotation(Property);
        var aliasName =
            property?.getField(PropertyField.alias)?.toStringValue();
        aliasName ??= "";

        var fieldName = element.displayName;
        var isFinal = element.isFinal;
        var fieldType = element.type;
        fieldInfos.add(FieldInfo(fieldName, fieldType, aliasName, isFinal));
      }
    }

    return fieldInfos;
  }

  List<PropertyInfo> _getPropertyInfoList() {
    var propInfos = <PropertyInfo>[];
    var accessors = _classElement.accessors;
    for (var accessor in accessors) {
      var ignored = accessor.getAnnotation(IgnoredProperty);
      if (ignored != null) {
        continue;
      }

      if (accessor.isSetter && accessor.correspondingGetter == null) {
        throw InvalidGenerationSourceError(
            'A getter accessor must be defined for corresponding setter '
            '${accessor.displayName}',
            element: _classElement);
      }

      if (accessor.isGetter) {
        var iterable = propInfos.where(
            (element) => element.setterFieldName == accessor.displayName);

        if (iterable.isEmpty) {
          var propInfo = PropertyInfo(accessor.returnType);
          propInfo.getterFieldName = accessor.displayName;

          var property = accessor.getAnnotation(Property);
          var aliasName =
              property?.getField(PropertyField.alias)?.toStringValue();
          aliasName ??= "";
          propInfo.aliasName = aliasName;
          propInfos.add(propInfo);
        } else {
          var propInfo = iterable.first;
          propInfo.getterFieldName = accessor.displayName;

          var property = accessor.getAnnotation(Property);
          var aliasName =
              property?.getField(PropertyField.alias)?.toStringValue();
          aliasName ??= "";
          propInfo.aliasName = aliasName;
        }
      } else if (accessor.isSetter) {
        var iterable = propInfos.where(
            (element) => element.getterFieldName == accessor.displayName);

        if (iterable.isEmpty) {
          var propInfo = PropertyInfo(accessor.variable.type);
          propInfo.setterFieldName = accessor.displayName;

          var property = accessor.getAnnotation(Property);
          var aliasName =
              property?.getField(PropertyField.alias)?.toStringValue();
          aliasName ??= "";
          propInfo.aliasName = aliasName;
          propInfos.add(propInfo);
        } else {
          var propInfo = iterable.first;
          propInfo.setterFieldName = accessor.displayName;

          var property = accessor.getAnnotation(Property);
          var aliasName =
              property?.getField(PropertyField.alias)?.toStringValue();
          aliasName ??= "";
          propInfo.aliasName = aliasName;
        }
      }
    }

    return propInfos;
  }

  void _validateConverter(ConstructorInfo ctorInfo,
      List<PropertyInfo> propertyInfoList, List<FieldInfo> fieldInfoList) {
    // 1. ctor with all positional optional parameters
    //    1.1 all fields has to be non-final, otherwise those can not
    //        be set in ctor with positional optional parameters
    // 2. ctor with all named optional parameters
    //    2.1 all fields either has to be final or all non-final, no
    //        mix-and-match is allowed.
    //    2.2 all field names in the class must match with ctor parameters

    if (ctorInfo.hasAllOptionalPositionalCtor) {
      if (fieldInfoList.any((field) => field.isFinal)) {
        throw InvalidGenerationSourceError(
            'A class with a constructor having all positional optional '
            'parameters should not have a final field.',
            element: _classElement);
      }
    }

    if (ctorInfo.hasAllOptionalNamedCtor) {
      if (fieldInfoList.any((field) => field.isFinal) &&
          fieldInfoList.any((field) => !field.isFinal)) {
        throw InvalidGenerationSourceError(
            'A class with a constructor having all named optional parameters '
            'should either have all fields as final or all fields as non-final, '
            'combination of final and non-final field is not allowed',
            element: _classElement);
      }

      if (!UnorderedIterableEquality().equals(
          fieldInfoList.map((e) => e.fieldName), ctorInfo.ctorParamNames)) {
        throw InvalidGenerationSourceError(
            'A class with a constructor having all named optional parameters '
            'should have all the fields\' names matching with the name of the '
            'constructor parameters.',
            element: _classElement);
      }
    }

    // check for an accessor if getter-setter both are available, otherwise
    // throw error.
    for (var propInfo in propertyInfoList) {
      if (propInfo.getterFieldName.isEmpty) {
        throw InvalidGenerationSourceError(
            'Getter accessor is not defined for ${propInfo.setterFieldName}',
            element: _classElement);
      }

      if (propInfo.setterFieldName.isEmpty) {
        throw InvalidGenerationSourceError(
            'Setter accessor is not defined for ${propInfo.getterFieldName}',
            element: _classElement);
      }
    }
  }
}
