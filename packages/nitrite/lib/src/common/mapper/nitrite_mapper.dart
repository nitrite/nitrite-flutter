import 'package:nitrite/nitrite.dart';

/// Represents a mapper which will convert an object of one
/// type to an object of another type.
abstract class NitriteMapper extends NitritePlugin {
  /// Tries to convert an object of type [Source] to an object of type [Target].
  /// If the conversion is not possible, it will return the source object.
  dynamic tryConvert<Target, Source>(Source? source);
}
