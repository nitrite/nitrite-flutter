import 'package:nitrite/nitrite.dart';

/// An abstract class that provides a method to try converting an object of
/// one type to another type.
abstract class NitriteMapper extends NitritePlugin {
  /// Tries to convert an object of type [Source] to an object of type [Target].
  /// If the conversion is not possible, it will return the source object.
  dynamic tryConvert<Target, Source>(Source? source);
}
