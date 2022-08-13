import 'package:nitrite/nitrite.dart';

/// Represents a mapper which will convert an object of one
/// type to an object of another type.
abstract class NitriteMapper extends NitritePlugin {
  /// Converts an object of type [Source] to an object of type [Target].
  Target? convert<Target, Source>(Source? source);

  /// Checks if the provided type is registered as a value type.
  ///
  /// A value type is a dart type which does not need to be
  /// converted to a [Document], i.e. dart build-in types.
  ///
  /// NOTE: An exact match of type is required.
  bool isValueType<T>();

  /// Checks if an object is of a value type.
  ///
  /// It will return `true` only if an **exact** type match is found.
  bool isValue(dynamic value);

  /// Creates and returns a new instance of the provided type.
  T newInstance<T>();
}

/// A factory method to create an instance of a [T].
typedef MappableFactory<T extends Mappable> = T Function();

/// An object that maps itself into a [Document] and vice versa.
abstract class Mappable {
  /// Writes the instance data to a [Document] and returns it.
  Document write(NitriteMapper? mapper);

  /// Reads the [document] and populate all fields of this instance.
  void read(NitriteMapper? mapper, Document document);
}
