import 'package:meta/meta_meta.dart';
import 'package:nitrite/nitrite.dart';

/// Annotation to mark a field as the id field of a repository.
@Target({TargetKind.field})
class Id {
  /// The custom name of the field.
  final String fieldName;

  /// The name of the embedded fields
  final List<String> embeddedFields;

  const Id({this.fieldName = '', this.embeddedFields = const []});
}

/// Annotation to mark a field as indexed.
@Target({TargetKind.classType})
class Index {
  /// The field name to be indexed.
  final List<String> fields;

  /// Type of the index.
  final String type;

  const Index({required this.fields, this.type = IndexType.unique});
}

/// Annotation to mark a class as an entity. An entity is a persistent class
/// which can be stored in an [ObjectRepository].
@Target({TargetKind.classType})
class Entity {
  /// Name of the [ObjectRepository]. By default,
  /// the name would be the class name of the entity.
  final String name;

  /// A list of indices for the repository.
  final List<Index> indices;

  const Entity({this.name = "", this.indices = const []});
}

/// Specifies nitrite code generators to generate
/// the code for [EntityConverter] implementation of
/// the marked class.
@Target({TargetKind.classType})
class Convertable {
  /// Specifies the generated class name, default is empty.
  /// If empty, it will generate the class with name
  /// <marked class name>Converter
  final String className;

  const Convertable({this.className = ""});
}

/// Specifies nitrite code generators to consider the marked
/// field/accessor as a document key while generating document
/// mapping code.
@Target({TargetKind.field, TargetKind.getter, TargetKind.setter})
class DocumentKey {
  /// Specifies the alias name of the key.
  final String alias;

  const DocumentKey({this.alias = ""});
}

/// Specifies nitrite code generators to ignore the marked
/// field/accessor while generating document mapping code.
@Target({TargetKind.field, TargetKind.getter, TargetKind.setter})
class IgnoredKey {
  const IgnoredKey();
}
