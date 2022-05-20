import 'package:nitrite/src/common/meta/attributes.dart';

/// Interface to be implemented by database objects that wish to be
/// aware of their metadata attributes.
abstract class AttributesAware {
  /// Returns the metadata [attributes] of an object.
  Attributes get attributes;

  /// Sets new meta data [attributes].
  set attributes(Attributes attributes);
}
