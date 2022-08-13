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

class EntityInfo {
  final String className;

  late String entityName;
  late List<EntityIndex> entityIndices;

  EntityId? entityId;

  EntityInfo(this.className);
}
