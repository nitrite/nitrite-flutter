import 'package:analyzer/dart/element/type.dart';
import 'package:nitrite/nitrite.dart';

abstract class EntityField {
  static const entityName = 'name';
  static const entityIndices = 'indices';
}

abstract class IndexField {
  static const fields = "fields";
  static const type = "type";
}

abstract class IdField {
  static const fieldName = "fieldName";
  static const embeddedFields = "embeddedFields";
}

abstract class ConverterField {
  static const className = 'className';
}

abstract class PropertyField {
  static const alias = 'alias';
}

class EntityInfo {
  final String className;

  late String entityName;
  late List<EntityIndex> entityIndices;

  EntityId? entityId;

  EntityInfo(this.className);
}

class ConverterInfo {
  final String className;
  final String converterName;
  final List<FieldInfo> fieldInfoList;
  final List<PropertyInfo> propertyInfoList;
  final ConstructorInfo constructorInfo;

  ConverterInfo(this.className,
      [this.converterName = "",
      this.fieldInfoList = const [],
      this.propertyInfoList = const [],
      this.constructorInfo = const ConstructorInfo()]);

  @override
  String toString() {
    return 'ConverterInfo{'
        'className: $className, '
        'converterName: $converterName, '
        'fieldInfoList: $fieldInfoList, '
        'propertyInfoList: $propertyInfoList, '
        'constructorInfo: $constructorInfo}';
  }
}

class FieldInfo {
  final String fieldName;
  final DartType fieldType;
  String aliasName;
  bool isFinal;
  bool isIgnored;
  bool setNull;

  FieldInfo(this.fieldName, this.fieldType,
      [this.aliasName = "",
      this.isFinal = false,
      this.isIgnored = false,
      this.setNull = false]);

  @override
  String toString() {
    return 'FieldInfo{'
        'fieldName: $fieldName, '
        'fieldType: $fieldType, '
        'aliasName: $aliasName, '
        'isFinal: $isFinal, '
        'setNull: $setNull, '
        'isIgnored: $isIgnored}';
  }
}

class PropertyInfo {
  String getterFieldName;
  String setterFieldName;
  DartType fieldType;
  String aliasName;
  bool isIgnored;

  PropertyInfo(this.fieldType,
      {this.getterFieldName = '',
      this.setterFieldName = '',
      this.aliasName = '',
      this.isIgnored = false});

  @override
  String toString() {
    return 'PropertyInfo{'
        'getterFieldName: $getterFieldName, '
        'setterFieldName: $setterFieldName, '
        'fieldType: $fieldType, '
        'aliasName: $aliasName, '
        'isIgnored: $isIgnored}';
  }
}

class ParamInfo {
  final String paramName;
  final DartType paramType;
  final bool isRequired;
  final bool isNamed;

  ParamInfo(this.paramType,
      [this.paramName = '', this.isRequired = false, this.isNamed = false]);

  @override
  String toString() {
    return 'ParamInfo{'
        'paramName: $paramName, '
        'paramType: $paramType, '
        'isRequired: $isRequired}';
  }
}

class ConstructorInfo {
  final bool hasDefaultCtor;
  final bool hasAllOptionalNamedCtor;
  final bool hasAllOptionalPositionalCtor;
  final bool hasAllNamedCtor;
  final List<ParamInfo> ctorParams;

  const ConstructorInfo(
      {this.hasDefaultCtor = false,
      this.hasAllOptionalNamedCtor = false,
      this.hasAllOptionalPositionalCtor = false,
      this.hasAllNamedCtor = false,
      this.ctorParams = const []});

  @override
  String toString() {
    return 'ConstructorInfo{'
        'hasDefaultCtor: $hasDefaultCtor, '
        'hasAllOptionalNamedCtor: $hasAllOptionalNamedCtor, '
        'hasAllOptionalPositionalCtor: $hasAllOptionalPositionalCtor, '
        'hasAllNamedCtor: $hasAllNamedCtor, '
        'ctorParams: $ctorParams}';
  }
}
