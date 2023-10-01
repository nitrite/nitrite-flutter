// ignore_for_file: implementation_imports

import 'dart:convert';

import 'package:hive/hive.dart';

import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';

/// @nodoc
class KeyCodec {
  final TypeRegistry _typeRegistry;

  KeyCodec(this._typeRegistry);

  String encode(dynamic key) {
    var writer = BinaryWriterImpl(_typeRegistry);
    writer.write(key);
    var bytes = writer.toBytes();
    return base64.encode(bytes);
  }

  dynamic decode(String base64Key) {
    var bytes = base64.decode(base64Key);
    var reader = BinaryReaderImpl(bytes, _typeRegistry);
    return reader.read();
  }
}
