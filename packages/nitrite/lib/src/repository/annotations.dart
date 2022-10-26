import 'package:meta/meta_meta.dart';
import 'package:nitrite/nitrite.dart';

/// Indicates that an annotated field is the id field.
@Target({TargetKind.field})
class Id {
  /// The custom name of the field.
  final String fieldName;

  /// The name of the embedded fields
  final List<String> embeddedFields;

  const Id({required this.fieldName, this.embeddedFields = const []});
}

/// Specifies a field to be indexed.
@Target({TargetKind.classType})
class Index {
  /// The field name to be indexed.
  final List<String> fields;

  /// Type of the index.
  final String type;

  const Index({required this.fields, this.type = IndexType.unique});
}

/// Represents an entity for an [ObjectRepository].
@Target({TargetKind.classType})
class Entity {
  /// Name of the [ObjectRepository]. By default,
  /// the name would be the class name of the entity.
  final String name;

  /// Index definitions of the entity.
  final List<Index> indices;

  const Entity({this.name = "", this.indices = const []});
}

@Target({TargetKind.classType})
class Converter {
  final String className;

  const Converter({this.className = ""});
}

@Target({TargetKind.field, TargetKind.getter, TargetKind.setter})
class Property {
  final String alias;

  const Property({this.alias = ""});
}

@Target({TargetKind.field, TargetKind.getter, TargetKind.setter})
class IgnoredProperty {
  const IgnoredProperty();
}
