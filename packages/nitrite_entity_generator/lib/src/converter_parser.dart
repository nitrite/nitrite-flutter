import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:collection/collection.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite_entity_generator/src/common.dart';
import 'package:nitrite_entity_generator/src/extensions.dart';
import 'package:nitrite_entity_generator/src/parser.dart';
import 'package:nitrite_entity_generator/src/type_validator.dart';
import 'package:source_gen/source_gen.dart';

class ConverterParser extends Parser<ConverterInfo> {
  final ClassElement _classElement;

  ConverterParser(this._classElement);

  @override
  ConverterInfo parse() {
    var className = _getClassName();

    // generated class name
    var converterName = _getConverterName();

    // constructor information
    var ctorInfo = _getConstructorInfo();

    // field information
    var fieldInfoList = _getFieldInfoList();

    // property information
    var propertyInfoList = _getPropertyInfoList();

    // validate the class and filter out duplicate information
    _validateConverter(ctorInfo, propertyInfoList, fieldInfoList);

    return ConverterInfo(
        className, converterName, fieldInfoList, propertyInfoList, ctorInfo);
  }

  String _getConverterName() {
    var converterName = _classElement
        .getAnnotation(GenerateConverter)
        ?.getField(ConverterField.className)
        ?.toStringValue();

    if (converterName == null || converterName.isEmpty) {
      return '${_classElement.displayName}Converter';
    } else {
      return converterName;
    }
  }

  bool _isValidField(FieldElement element) {
    // validate valid type
    element.type.accept(TypeValidator(element));

    var property = element.getAnnotation(DocumentKey);
    if (property != null &&
        (element.isStatic || element.isPrivate || element.isSynthetic)) {
      /*
      * class A {
      *   @DocumentKey
      *   static String a;
      *
      *   @DocumentKey
      *   String? _b;
      * }
      *
      * 1. private fields cannot be set from outside of the class.
      *
      * 2. static fields also does not hold any state of the object,
      *    so converting it to a document is not valid.
      *
      * 3. synthetic fields are not part of the user objects, so
      *    converting it to a document is also not valid.
      * */

      throw InvalidGenerationSourceError(
        '`@DocumentKey` cannot be used on a private/static/synthetic field.',
        element: element,
      );
    }

    // if (_classElement.displayName.contains('Company')) {
    //   var type = element.type;
    //   if (type.isDartCoreMap) {
    //     type.accept(GenericTypeVisitor());
    //   }
    // }

    if (element.isPrivate) return false;
    if (element.isStatic) return false;
    if (element.isSynthetic) return false;
    return true;
  }

  String _getClassName() {
    // check mixin
    if (_classElement.mixins.isNotEmpty) {
      /*
      * mixin A {
      *   String? a;
      * }
      *
      * 1. mixins can not be instantiated
      * */

      throw InvalidGenerationSourceError(
        '`@GenerateConverter` can not be used with mixins.',
        element: _classElement,
      );
    }

    if (_classElement.isAbstract) {
      /*
      * abstract class A {
      *   String? a;
      * }
      *
      * 1. abstract class can not be instantiated
      * */

      throw InvalidGenerationSourceError(
        '`@GenerateConverter` can not be used on abstract class.',
        element: _classElement,
      );
    }

    return _classElement.displayName;
  }

  ConstructorInfo _getConstructorInfo() {
    // check for valid constructors
    var constructors = _classElement.constructors;
    var validConstructors = constructors.where((ctor) =>
        ctor.isPublic &&
        ctor.name.isEmpty &&
        (ctor.isGenerative || !ctor.isFactory || ctor.isDefaultConstructor));

    /*
      * Valid Constructor
      *
      *   1. DEFAULT CTOR
      *
      * class A {
      *   String? name;
      * }
      *
      *   2. CTOR WITH ALL POSITIONAL OPTIONAL PARAMETERS
      *
      * class A {
      *   String name;
      *   A([this.name = 'a']);
      * }
      *   3. CTOR WITH ALL NAMED (OPTIONAL/REQUIRED) PARAMETERS
      *
      * class A {
      *   final String name;
      *   A({this.name = 'a'});
      * }
      *
      * class B {
      *   final String name;
      *   B({required this.name});
      * }
      * */

    if (validConstructors.isEmpty) {
      throw InvalidGenerationSourceError(
        '`@GenerateConverter` can only be used on classes which has at least '
        'one public constructor which is either a default constructor or one '
        'with all optional/named parameters.',
        element: _classElement,
      );
    }

    bool hasDefaultCtor =
        validConstructors.any((ctor) => ctor.parameters.isEmpty);

    bool hasAllOptionalPositionalCtor = validConstructors.any((ctor) =>
        ctor.parameters.isNotEmpty &&
        ctor.parameters.every((param) => param.isOptionalPositional));

    bool hasAllOptionalNamedCtor = validConstructors.any((ctor) =>
        ctor.parameters.isNotEmpty &&
        ctor.parameters.every((param) => param.isOptionalNamed));

    bool hasAllNamedCtor = validConstructors.any((ctor) =>
        ctor.parameters.isNotEmpty &&
        ctor.parameters.every((param) => param.isNamed));

    var ctorParams = <ParamInfo>[];
    for (var ctor in validConstructors) {
      var params = ctor.parameters
          .map((e) => ParamInfo(e.type, e.displayName, e.isRequired, e.isNamed))
          .toList();
      if (params.length > ctorParams.length) {
        ctorParams = params;
      }
    }

    return ConstructorInfo(
        hasDefaultCtor: hasDefaultCtor,
        hasAllOptionalNamedCtor: hasAllOptionalNamedCtor,
        hasAllOptionalPositionalCtor: hasAllOptionalPositionalCtor,
        hasAllNamedCtor: hasAllNamedCtor,
        ctorParams: ctorParams);
  }

  List<FieldInfo> _getFieldInfoList() {
    var fieldInfos = <FieldInfo>{};
    var fieldElements = _classElement.fields;
    for (var element in fieldElements) {
      if (_isValidField(element)) {
        // find out if alias is provided
        var property = element.getAnnotation(DocumentKey);
        var aliasName =
            property?.getField(PropertyField.alias)?.toStringValue();
        aliasName ??= "";

        var fieldName = element.displayName;
        var isFinal = element.isFinal;
        var fieldType = element.type;
        var isIgnored = element.getAnnotation(IgnoredKey) != null;
        fieldInfos.add(
            FieldInfo(fieldName, fieldType, aliasName, isFinal, isIgnored));
      }
    }

    // get field details from parents
    var supertypes = _classElement.allSupertypes;
    for (var type in supertypes) {
      // use recursion to scan the heirarchy
      var superParser = ConverterParser(type.element as ClassElement);
      var superFieldInfos = superParser._getFieldInfoList();
      if (superFieldInfos.isNotEmpty) {
        fieldInfos.addAll(superFieldInfos);
      }
    }

    return fieldInfos.toList();
  }

  List<PropertyInfo> _getPropertyInfoList() {
    var propInfos = <PropertyInfo>{};
    var accessors = _classElement.accessors;

    for (var accessor in accessors) {
      // validate valid type
      accessor.type.accept(TypeValidator(accessor));

      // synthentic properties are ignored
      if (accessor.isSynthetic) continue;

      if (accessor.isSetter && accessor.correspondingGetter == null) {
        /*
        * class A {
        *   // no way to get the value
        *   String _name;
        *
        *   A([this._name = 'a']);
        *
        *   void set name(value) {
        *     this._name = value;
        *   }
        * }
        * */

        throw InvalidGenerationSourceError(
            'A getter accessor must be defined for corresponding setter '
            '${accessor.displayName}',
            element: _classElement);
      }

      if (accessor.isGetter) {
        // combine getter and setter accessors
        var iterable = propInfos.where(
            (element) => element.setterFieldName == accessor.displayName);

        if (iterable.isEmpty) {
          // setter not found yet, build the propInfo based on getter first
          var propInfo = PropertyInfo(accessor.returnType);
          propInfo.getterFieldName = accessor.displayName;
          propInfo.isIgnored = accessor.getAnnotation(IgnoredKey) != null;

          var property = accessor.getAnnotation(DocumentKey);
          var aliasName =
              property?.getField(PropertyField.alias)?.toStringValue();
          aliasName ??= "";
          propInfo.aliasName = aliasName;
          propInfos.add(propInfo);
        } else {
          // setter already found, update the getter info in existing propInfo
          var propInfo = iterable.first;
          propInfo.getterFieldName = accessor.displayName;
          propInfo.isIgnored = accessor.getAnnotation(IgnoredKey) != null;

          var property = accessor.getAnnotation(DocumentKey);
          var aliasName =
              property?.getField(PropertyField.alias)?.toStringValue();
          aliasName ??= "";
          propInfo.aliasName = aliasName;
        }
      } else if (accessor.isSetter) {
        // combine getter and setter accessors
        var iterable = propInfos.where(
            (element) => element.getterFieldName == accessor.displayName);

        if (iterable.isEmpty) {
          // getter not found yet, build the propInfo based on setter first
          var propInfo = PropertyInfo(accessor.variable.type);
          propInfo.setterFieldName = accessor.displayName;
          propInfo.isIgnored = accessor.getAnnotation(IgnoredKey) != null;

          var property = accessor.getAnnotation(DocumentKey);
          var aliasName =
              property?.getField(PropertyField.alias)?.toStringValue();
          aliasName ??= "";
          propInfo.aliasName = aliasName;
          propInfos.add(propInfo);
        } else {
          // getter already found, update the setter info in existing propInfo
          var propInfo = iterable.first;
          propInfo.setterFieldName = accessor.displayName;
          propInfo.isIgnored = accessor.getAnnotation(IgnoredKey) != null;

          var property = accessor.getAnnotation(DocumentKey);
          var aliasName =
              property?.getField(PropertyField.alias)?.toStringValue();
          aliasName ??= "";
          propInfo.aliasName = aliasName;
        }
      }
    }

    // get property info from parents
    var supertypes = _classElement.allSupertypes;
    for (var type in supertypes) {
      // use recursion to scan the heirarchy
      var superParser = ConverterParser(type.element as ClassElement);
      var superPropInfos = superParser._getPropertyInfoList();
      if (superPropInfos.isNotEmpty) {
        propInfos.addAll(superPropInfos);
      }
    }

    return propInfos.toList();
  }

  void _validateConverter(ConstructorInfo ctorInfo,
      List<PropertyInfo> propertyInfoList, List<FieldInfo> fieldInfoList) {
    // 1. ctor with all positional optional parameters
    //    1.1 all fields has to be non-final, otherwise those can not
    //        be set in ctor with positional optional parameters
    // 2. ctor with all named (optional/required) parameters
    //    2.1 all field names in the class must match with ctor parameters

    if (ctorInfo.hasAllOptionalPositionalCtor) {
      /*
      * class A {
      *   // cannot set it in converter as ctor param is positional
      *   final String name;
      *   String? address;
      *
      *   A([this.name = 'a', this.address]);
      * }
      *
      * */

      if (fieldInfoList.any((field) => field.isFinal)) {
        throw InvalidGenerationSourceError(
            'A class with a constructor having all positional optional '
            'parameters should not have a final field.',
            element: _classElement);
      }
    }

    if (ctorInfo.hasAllOptionalNamedCtor || ctorInfo.hasAllNamedCtor) {
      if (!UnorderedIterableEquality().equals(
          fieldInfoList.map((e) => e.fieldName),
          ctorInfo.ctorParams.map((e) => e.paramName))) {
        /*
        * class A {
        *   final String name;
        *   String? address;
        *
        *   A({this.name = 'a'});
        * }
        *
        * */

        throw InvalidGenerationSourceError(
            'A class with a constructor having all named parameters '
            'should have all the fields\' names matching with the name of the '
            'constructor parameters.',
            element: _classElement);
      }
    }

    if (!ctorInfo.hasDefaultCtor &&
        !ctorInfo.hasAllOptionalNamedCtor &&
        !ctorInfo.hasAllNamedCtor &&
        !ctorInfo.hasAllOptionalPositionalCtor) {
      // no allowable constructor found to instantiate the class

      throw InvalidGenerationSourceError(
          'No suitable constructor found for the class '
          '${_classElement.displayName}. A class should have at least one public '
          'constructor which is either a default constructor or one with all '
          'optional/named parameters.',
          element: _classElement);
    }

    for (var fieldInfo in fieldInfoList) {
      if (fieldInfo.isIgnored) {
        var ctorParams = ctorInfo.ctorParams;
        var ctorParam = ctorParams
            .where((p) => p.paramName == fieldInfo.fieldName)
            .firstOrNull;

        if (ctorParam != null && ctorParam.isRequired) {
          var isNullable = ctorParam.paramType.nullabilitySuffix ==
              NullabilitySuffix.question;
          if (!isNullable) {
            /*
            * class A {
            *   @IgnoredKey()
            *   String name;
            *   String address;
            *
            *   // nothing to set for this.name as it is required and
            *   // at the same time ignored
            *   A({required this.name, required this.address});
            * }
            *
            * */

            throw InvalidGenerationSourceError(
                'A required named constructor parameter ${ctorParam.paramName} '
                'with non-nullable type cannot be ignored',
                element: _classElement);
          } else {
            // if nullable set null during constructor call
            fieldInfo.setNull = true;
          }
        }
      }
    }

    // remove inherited getters of Object class
    propertyInfoList
        .removeWhere((propInfo) => 'hashCode' == propInfo.getterFieldName);
    propertyInfoList
        .removeWhere((propInfo) => 'runtimeType' == propInfo.getterFieldName);

    // remove property which is same with existing field names
    propertyInfoList.removeWhere((propInfo) => fieldInfoList
        .map((fieldInfo) => fieldInfo.fieldName)
        .contains(propInfo.getterFieldName));

    // check for an accessor if getter-setter both are available, otherwise
    // throw error.
    for (var propInfo in propertyInfoList) {
      if (propInfo.getterFieldName.isEmpty) {
        /*
        * class A {
        *   String? _name;
        *
        *   void set name(value) {
        *     _name = value;
        *   }
        * }
        * */

        throw InvalidGenerationSourceError(
            'Getter accessor is not defined for ${propInfo.setterFieldName}',
            element: _classElement);
      }

      if (propInfo.setterFieldName.isEmpty) {
        /*
        * class A {
        *   String? _name;
        *
        *   String? get name => _name;
        * }
        * */

        throw InvalidGenerationSourceError(
            'Setter accessor is not defined for ${propInfo.getterFieldName}',
            element: _classElement);
      }
    }
  }
}
