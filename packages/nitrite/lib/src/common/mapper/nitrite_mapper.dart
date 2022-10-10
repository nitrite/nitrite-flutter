import 'package:nitrite/nitrite.dart';

/// Represents a mapper which will convert an object of one
/// type to an object of another type.
abstract class NitriteMapper extends NitritePlugin {
  /// Converts an object of type [Source] to an object of type [Target].
  Target? convert<Target, Source>(Source? source);
}

/// A class that implements this interface can be used to convert
/// entity into a database {@link Document} and back again.
abstract class EntityConverter<T> {
  /// Gets the entity type.
  Type get entityType => T;

  /// Converts the entity to a [Document].
  Document toDocument(T entity, NitriteMapper nitriteMapper);

  /// Converts a [Document] to an entity of type [T].
  T fromDocument(Document document, NitriteMapper nitriteMapper);
}
