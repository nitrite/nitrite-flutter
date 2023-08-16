import 'dart:convert';
import 'dart:typed_data';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite_support/src/exchange/convert/converter_registry.dart';
import 'package:nitrite_support/src/exchange/convert/type_token.dart';

class BinaryWriter {
  static const _initBufferSize = 4096;
  static const _utf8Encoder = Utf8Encoder();
  final ConverterRegistry _converterRegistry;

  var _buffer = Uint8List(_initBufferSize);

  ByteData? _byteDataInstance;
  int _offset = 0;

  BinaryWriter(this._converterRegistry);

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  ByteData get _byteData {
    _byteDataInstance ??= ByteData.view(_buffer.buffer);
    return _byteDataInstance!;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _reserveBytes(int count) {
    if (_buffer.length - _offset < count) {
      _increaseBufferSize(count);
    }
  }

  void _increaseBufferSize(int count) {
// We will create a list in the range of 2-4 times larger than required.
    var newSize = _pow2roundup((_offset + count) * 2);
    var newBuffer = Uint8List(newSize);
    newBuffer.setRange(0, _offset, _buffer);
    _buffer = newBuffer;
    _byteDataInstance = null;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _addBytes(List<int> bytes) {
    ArgumentError.checkNotNull(bytes);

    var length = bytes.length;
    _reserveBytes(length);
    _buffer.setRange(_offset, _offset + length, bytes);
    _offset += length;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeByte(int byte) {
    ArgumentError.checkNotNull(byte);

    _reserveBytes(1);
    _buffer[_offset++] = byte;
  }

  void writeWord(int value) {
    ArgumentError.checkNotNull(value);

    _reserveBytes(2);
    _buffer[_offset++] = value;
    _buffer[_offset++] = value >> 8;
  }

  void writeInt32(int value) {
    ArgumentError.checkNotNull(value);

    _reserveBytes(4);
    _byteData.setInt32(_offset, value, Endian.little);
    _offset += 4;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeUint32(int value) {
    ArgumentError.checkNotNull(value);

    _reserveBytes(4);
    _buffer.writeUint32(_offset, value);
    _offset += 4;
  }

  void writeInt(int value) {
    writeDouble(value.toDouble());
  }

  void writeDouble(double value) {
    ArgumentError.checkNotNull(value);

    _reserveBytes(8);
    _byteData.setFloat64(_offset, value, Endian.little);
    _offset += 8;
  }

  void writeBool(bool value) {
    ArgumentError.checkNotNull(value);

    writeByte(value ? 1 : 0);
  }

  void writeString(
    String value, {
    bool writeByteCount = true,
    Converter<String, List<int>> encoder = _utf8Encoder,
  }) {
    ArgumentError.checkNotNull(value);

    var bytes = encoder.convert(value);
    if (writeByteCount) {
      writeUint32(bytes.length);
    }
    _addBytes(bytes);
  }

  void writeByteList(List<int> bytes, {bool writeLength = true}) {
    ArgumentError.checkNotNull(bytes);

    if (writeLength) {
      writeUint32(bytes.length);
    }
    _addBytes(bytes);
  }

  void writeIntList(List<int> list, {bool writeLength = true}) {
    ArgumentError.checkNotNull(list);

    var length = list.length;
    if (writeLength) {
      writeUint32(length);
    }
    _reserveBytes(length * 8);
    var byteData = _byteData;
    for (var i = 0; i < length; i++) {
      byteData.setFloat64(_offset, list[i].toDouble(), Endian.little);
      _offset += 8;
    }
  }

  void writeDoubleList(List<double> list, {bool writeLength = true}) {
    ArgumentError.checkNotNull(list);

    var length = list.length;
    if (writeLength) {
      writeUint32(length);
    }
    _reserveBytes(length * 8);
    var byteData = _byteData;
    for (var i = 0; i < length; i++) {
      byteData.setFloat64(_offset, list[i], Endian.little);
      _offset += 8;
    }
  }

  void writeBoolList(List<bool> list, {bool writeLength = true}) {
    ArgumentError.checkNotNull(list);

    var length = list.length;
    if (writeLength) {
      writeUint32(length);
    }
    _reserveBytes(length);
    for (var i = 0; i < length; i++) {
      _buffer[_offset++] = list[i] ? 1 : 0;
    }
  }

  void writeStringList(
    List<String> list, {
    bool writeLength = true,
    Converter<String, List<int>> encoder = _utf8Encoder,
  }) {
    ArgumentError.checkNotNull(list);

    if (writeLength) {
      writeUint32(list.length);
    }
    for (var str in list) {
      var strBytes = encoder.convert(str);
      writeUint32(strBytes.length);
      _addBytes(strBytes);
    }
  }

  void writeList(List list, {bool writeLength = true}) {
    ArgumentError.checkNotNull(list);

    if (writeLength) {
      writeUint32(list.length);
    }
    for (var i = 0; i < list.length; i++) {
      write(list[i]);
    }
  }

  void writeMap(Map<dynamic, dynamic> map, {bool writeLength = true}) {
    ArgumentError.checkNotNull(map);

    if (writeLength) {
      writeUint32(map.length);
    }
    for (var key in map.keys) {
      write(key);
      write(map[key]);
    }
  }

  void write<T>(T value, {bool writeTypeId = true}) {
    if (value == null) {
      if (writeTypeId) {
        writeByte(TypeToken.nullT);
      }
    } else if (value is int) {
      if (writeTypeId) {
        writeByte(TypeToken.intT);
      }
      writeInt(value);
    } else if (value is double) {
      if (writeTypeId) {
        writeByte(TypeToken.doubleT);
      }
      writeDouble(value);
    } else if (value is bool) {
      if (writeTypeId) {
        writeByte(TypeToken.boolT);
      }
      writeBool(value);
    } else if (value is String) {
      if (writeTypeId) {
        writeByte(TypeToken.stringT);
      }
      writeString(value);
    } else if (value is List) {
      _writeList(value, writeTypeId: writeTypeId);
    } else if (value is Map) {
      if (writeTypeId) {
        writeByte(TypeToken.mapT);
      }
      writeMap(value);
    } else {
      var resolved = _converterRegistry.getConverterByValue(value);
      if (resolved == null) {
        throw NitriteException(
            'Cannot write, unknown type: ${value.runtimeType}. '
            'Did you forget to register a converter?');
      }
      if (writeTypeId) {
        writeByte(resolved.typeId);
      }
      resolved.encode(value, this);
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _writeList(List value, {bool writeTypeId = true}) {
    if (value.contains(null)) {
      if (writeTypeId) {
        writeByte(TypeToken.listT);
      }
      writeList(value);
    } else if (value is Uint8List) {
      if (writeTypeId) {
        writeByte(TypeToken.byteListT);
      }
      writeByteList(value);
    } else if (value is List<int>) {
      if (writeTypeId) {
        writeByte(TypeToken.intListT);
      }
      writeIntList(value);
    } else if (value is List<double>) {
      if (writeTypeId) {
        writeByte(TypeToken.doubleListT);
      }
      writeDoubleList(value);
    } else if (value is List<bool>) {
      if (writeTypeId) {
        writeByte(TypeToken.boolListT);
      }
      writeBoolList(value);
    } else if (value is List<String>) {
      if (writeTypeId) {
        writeByte(TypeToken.stringListT);
      }
      writeStringList(value);
    } else {
      if (writeTypeId) {
        writeByte(TypeToken.listT);
      }
      writeList(value);
    }
  }

  Uint8List toBytes() {
    return Uint8List.view(_buffer.buffer, 0, _offset);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static int _pow2roundup(int x) {
    assert(x > 0);
    --x;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return x + 1;
  }
}

extension Unint8ListX on Uint8List {
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readUint32(int offset) {
    return this[offset] |
        this[offset + 1] << 8 |
        this[offset + 2] << 16 |
        this[offset + 3] << 24;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeUint32(int offset, int value) {
    this[offset] = value;
    this[offset + 1] = value >> 8;
    this[offset + 2] = value >> 16;
    this[offset + 3] = value >> 24;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Uint8List view(int offset, int bytes) {
    return Uint8List.view(buffer, offsetInBytes + offset, bytes);
  }
}
