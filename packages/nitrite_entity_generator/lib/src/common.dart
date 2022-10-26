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
}

class FieldInfo {
  final String fieldName;
  final DartType fieldType;
  final String aliasName;
  final bool isFinal;

  FieldInfo(this.fieldName, this.fieldType,
      [this.aliasName = "", this.isFinal = false]);
}

class PropertyInfo {
  String getterFieldName;
  String setterFieldName;
  DartType fieldType;
  String aliasName;

  PropertyInfo(this.fieldType,
      {this.getterFieldName = '',
      this.setterFieldName = '',
      this.aliasName = ''});
}

class ConstructorInfo {
  final bool hasDefaultCtor;
  final bool hasAllOptionalNamedCtor;
  final bool hasAllOptionalPositionalCtor;
  final List<String> ctorParamNames;

  const ConstructorInfo(
      {this.hasDefaultCtor = false,
      this.hasAllOptionalNamedCtor = false,
      this.hasAllOptionalPositionalCtor = false,
      this.ctorParamNames = const []});

  @override
  String toString() {
    return 'ConstructorInfo{hasDefaultCtor: $hasDefaultCtor, '
        'hasAllNamedParamsCtor: $hasAllOptionalNamedCtor, '
        'hasAllOptionalParamsCtor: $hasAllOptionalPositionalCtor}';
  }
}
