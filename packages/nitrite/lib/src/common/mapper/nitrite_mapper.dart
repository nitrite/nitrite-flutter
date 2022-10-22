import 'package:nitrite/nitrite.dart';

/// Represents a mapper which will convert an object of one
/// type to an object of another type.
abstract class NitriteMapper extends NitritePlugin {
  /// Converts an object of type [Source] to an object of type [Target].
  Target? convert<Target, Source>(Source? source);
}
