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

  ConverterInfo(this.className,
      [this.converterName = "", this.fieldInfoList = const []]);
}

class FieldInfo {
  final String fieldName;
  final DartType fieldType;
  final String aliasName;

  FieldInfo(this.fieldName, this.fieldType, [this.aliasName = ""]);
}
