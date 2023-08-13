import 'package:nitrite_support/src/convert/binary_reader.dart';
import 'package:nitrite_support/src/convert/binary_writer.dart';

abstract class Converter<T> {
  int get typeId;
  void encode(T value, BinaryWriter writer);
  T decode(BinaryReader reader);

  bool matchesRuntimeType(dynamic value) => value.runtimeType == T;
  bool matchesType(dynamic value) => value is T;
}
