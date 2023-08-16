import 'dart:convert';
import 'dart:typed_data';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite_support/src/exchange/convert/binary_writer.dart';
import 'package:nitrite_support/src/exchange/convert/converter_registry.dart';
import 'package:nitrite_support/src/exchange/convert/type_token.dart';

class BinaryReader {
  static const _utf8Decoder = Utf8Decoder();
  final Uint8List _buffer;
  final ByteData _byteData;
  final ConverterRegistry _converterRegistry;
  final int _bufferLimit;
  int _offset = 0;

  BinaryReader(this._buffer, this._converterRegistry, [int? bufferLength])
      : _bufferLimit = bufferLength ?? _buffer.length,
        _byteData = ByteData.view(_buffer.buffer, _buffer.offsetInBytes);

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int get availableBytes => _bufferLimit - _offset;

  int get usedBytes => _offset;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _requireBytes(int bytes) {
    if (_offset + bytes > _bufferLimit) {
      throw RangeError('Not enough bytes available.');
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void skip(int bytes) {
    _requireBytes(bytes);
    _offset += bytes;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readByte() {
    _requireBytes(1);
    return _buffer[_offset++];
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Uint8List viewBytes(int bytes) {
    _requireBytes(bytes);
    _offset += bytes;
    return _buffer.view(_offset - bytes, bytes);
  }

  Uint8List peekBytes(int bytes) {
    _requireBytes(bytes);
    return _buffer.view(_offset, bytes);
  }

  int readWord() {
    _requireBytes(2);
    return _buffer[_offset++] | _buffer[_offset++] << 8;
  }

  int readInt32() {
    _requireBytes(4);
    _offset += 4;
    return _byteData.getInt32(_offset - 4, Endian.little);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readUint32() {
    _requireBytes(4);
    _offset += 4;
    return _buffer.readUint32(_offset - 4);
  }

  int peekUint32() {
    _requireBytes(4);
    return _buffer.readUint32(_offset);
  }

  int readInt() {
    return readDouble().toInt();
  }

  double readDouble() {
    _requireBytes(8);
    var value = _byteData.getFloat64(_offset, Endian.little);
    _offset += 8;
    return value;
  }

  bool readBool() {
    return readByte() > 0;
  }

  String readString(
      [int? byteCount, Converter<List<int>, String> decoder = _utf8Decoder]) {
    byteCount ??= readUint32();
    var view = viewBytes(byteCount);
    return decoder.convert(view);
  }

  Uint8List readByteList([int? length]) {
    length ??= readUint32();
    _requireBytes(length);
    var byteList = _buffer.sublist(_offset, _offset + length);
    _offset += length;
    return byteList;
  }

  List<int> readIntList([int? length]) {
    length ??= readUint32();
    _requireBytes(length * 8);
    var byteData = _byteData;
    var list = List<int>.filled(length, 0, growable: true);
    for (var i = 0; i < length; i++) {
      list[i] = byteData.getFloat64(_offset, Endian.little).toInt();
      _offset += 8;
    }
    return list;
  }

  List<double> readDoubleList([int? length]) {
    length ??= readUint32();
    _requireBytes(length * 8);
    var byteData = _byteData;
    var list = List<double>.filled(length, 0.0, growable: true);
    for (var i = 0; i < length; i++) {
      list[i] = byteData.getFloat64(_offset, Endian.little);
      _offset += 8;
    }
    return list;
  }

  List<bool> readBoolList([int? length]) {
    length ??= readUint32();
    _requireBytes(length);
    var list = List<bool>.filled(length, false, growable: true);
    for (var i = 0; i < length; i++) {
      list[i] = _buffer[_offset++] > 0;
    }
    return list;
  }

  List<String> readStringList(
      [int? length, Converter<List<int>, String> decoder = _utf8Decoder]) {
    length ??= readUint32();
    var list = List<String>.filled(length, '', growable: true);
    for (var i = 0; i < length; i++) {
      list[i] = readString(null, decoder);
    }
    return list;
  }

  List readList([int? length]) {
    length ??= readUint32();
    var list = List<dynamic>.filled(length, null, growable: true);
    for (var i = 0; i < length; i++) {
      list[i] = read();
    }
    return list;
  }

  Map readMap([int? length]) {
    length ??= readUint32();
    var map = <dynamic, dynamic>{};
    for (var i = 0; i < length; i++) {
      map[read()] = read();
    }
    return map;
  }

  dynamic read([int? typeId]) {
    typeId ??= readByte();
    switch (typeId) {
      case TypeToken.nullT:
        return null;
      case TypeToken.intT:
        return readInt();
      case TypeToken.doubleT:
        return readDouble();
      case TypeToken.boolT:
        return readBool();
      case TypeToken.stringT:
        return readString();
      case TypeToken.byteListT:
        return readByteList();
      case TypeToken.intListT:
        return readIntList();
      case TypeToken.doubleListT:
        return readDoubleList();
      case TypeToken.boolListT:
        return readBoolList();
      case TypeToken.stringListT:
        return readStringList();
      case TypeToken.listT:
        return readList();
      case TypeToken.mapT:
        return readMap();
      default:
        var resolved = _converterRegistry.getConverter(typeId);
        if (resolved == null) {
          throw NitriteException('Cannot read, unknown typeId: $typeId. '
              'Did you forget to register a Converter?');
        }
        return resolved.decode(this);
    }
  }
}
