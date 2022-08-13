import 'package:nitrite/nitrite.dart';

typedef Encoder<T> = String Function(T value);
typedef Decoder<T> = T Function(String value);

class Serializer<T> {
  final Encoder<T> encoder;
  final Decoder<T> decoder;

  Serializer({required this.encoder, required this.decoder});
}

class DateTimeSerializer extends Serializer<DateTime> {
  DateTimeSerializer() : super(
    encoder: (value) => value.toIso8601String(),
    decoder: (value) => DateTime.parse(value),
  );
}

class DurationSerializer extends Serializer<Duration> {
  DurationSerializer() : super(
    encoder: (value) => value.inMilliseconds.toString(),
    decoder: (value) => Duration(milliseconds: int.parse(value)),
  );
}

class NumberSerializer extends Serializer<num> {
  NumberSerializer() : super(
    encoder: (value) => value.toString(),
    decoder: (value) => num.parse(value),
  );
}

class IntSerializer extends Serializer<int> {
  IntSerializer() : super(
    encoder: (value) => value.toString(),
    decoder: (value) => int.parse(value),
  );
}

class DoubleSerializer extends Serializer<double> {
  DoubleSerializer() : super(
    encoder: (value) => value.toString(),
    decoder: (value) => double.parse(value),
  );
}

class StringSerializer extends Serializer<String> {
  StringSerializer() : super(
    encoder: (value) => value,
    decoder: (value) => value,
  );
}

class BoolSerializer extends Serializer<bool> {
  BoolSerializer() : super(
    encoder: (value) => value.toString(),
    decoder: (value) => value.toBool(),
  );
}

// ignore: prefer_void_to_null
class NullSerializer extends Serializer<Null> {
  NullSerializer() : super(
    encoder: (value) => 'null',
    decoder: (value) => null,
  );
}

class NitriteIdSerializer extends Serializer<NitriteId> {
  NitriteIdSerializer() : super(
    encoder: (value) => value.toString(),
    decoder: (value) => NitriteId.createId(value),
  );
}


extension on String {
  bool toBool() {
    if (toLowerCase() == 'true') {
      return true;
    } else if (toLowerCase() == 'false') {
      return false;
    }

    throw '"$this" can not be parsed to boolean.';
  }
}