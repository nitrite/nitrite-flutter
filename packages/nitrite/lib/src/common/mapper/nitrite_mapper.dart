import 'package:nitrite/nitrite.dart';

/// Represents a mapper which will convert an object of one
/// type to an object of another type.
abstract class NitriteMapper extends NitritePlugin {
  /// Converts an object of type [Source] to an object of type [Target].
  Target convert<Target, Source>(Source source);

  /// Checks if the provided type is registered as a value type.
  bool isValueType<T>();

  /// Checks if an object is of a value type.
  bool isValue(dynamic value);
}
