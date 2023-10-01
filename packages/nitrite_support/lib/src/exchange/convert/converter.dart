import 'package:nitrite_support/src/exchange/convert/binary_reader.dart';
import 'package:nitrite_support/src/exchange/convert/binary_writer.dart';

/// An abstract class representing a converter that can convert objects of
/// type [T] to another type.
abstract class Converter<T> {
  /// Returns the type ID of the converter.
  int get typeId;

  /// Encodes the given [value] using the provided [BinaryWriter].
  void encode(T value, BinaryWriter writer);

  /// Decodes the binary data read by the [BinaryReader] and returns
  /// the decoded object of type [T].
  T decode(BinaryReader reader);

  /// Returns true if the runtime type of the given [value] matches the type [T].
  bool matchesRuntimeType(dynamic value) => value.runtimeType == T;

  /// Returns true if the given [value] matches the type [T].
  bool matchesType(dynamic value) => value is T;
}
