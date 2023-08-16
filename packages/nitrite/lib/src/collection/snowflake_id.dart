import 'dart:math';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// @nodoc
class SnowflakeIdGenerator {
  final Random _random = Random.secure();
  final int _nodeIdBits = 10;
  final Logger _log = Logger('SnowflakeIdGenerator');

  int _nodeId = 0;
  int _sequence = 0;
  int _lastTimestamp = -1;

  SnowflakeIdGenerator() {
    var maxNodeId = ~(-1 << _nodeIdBits);
    _nodeId = _getNodeId();
    if (_nodeId > maxNodeId) {
      _log.warning("nodeId > maxNodeId; using random node id");
      _nodeId = _random.nextInt(maxNodeId) + 1;
    }
    _log.fine("Initialised with node id $_nodeId");
  }

  int get id {
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    if (timestamp < _lastTimestamp) {
      _log.warning('Clock moved backwards. Refusing to generate id for '
          '${_lastTimestamp - timestamp} milliseconds');
      Future.delayed(Duration(milliseconds: _lastTimestamp - timestamp));
    }

    var sequenceBits = 12;
    if (_lastTimestamp == timestamp) {
      var sequenceMask = ~(-1 << sequenceBits);
      _sequence = (_sequence + 1) & sequenceMask;
      if (_sequence == 0) {
        timestamp = _tillNextMillis(_lastTimestamp);
      }
    } else {
      _sequence = 0;
    }
    _lastTimestamp = timestamp;
    var timestampLeftShift = sequenceBits + _nodeIdBits;
    var no2epoch = 1288834974657;
    var id = ((timestamp - no2epoch) << timestampLeftShift) |
        (_nodeId << sequenceBits) |
        _sequence;

    if (id < 0) {
      _log.warning('Generated id is negative: $id');
    }
    return id;
  }

  int _getNodeId() {
    Uuid uuid = Uuid();
    var uid = ascii.encode(uuid.v4());
    var rndByte = _random.nextInt(0XFFFFFFFF) & 0x000000FF;

    return ((0x000000FF & uid[uid.length - 1]) |
            (0x0000FF00 & (rndByte << 8))) >>
        6;
  }

  int _tillNextMillis(int lastTimestamp) {
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    while (timestamp <= lastTimestamp) {
      timestamp = DateTime.now().millisecondsSinceEpoch;
    }
    return timestamp;
  }
}
