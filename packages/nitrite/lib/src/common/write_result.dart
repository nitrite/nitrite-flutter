import 'dart:async';

import 'package:nitrite/nitrite.dart';

class WriteResult extends Stream<NitriteId> {
  final Stream<NitriteId> _stream;

  WriteResult(Stream<NitriteId> stream)
      : _stream = stream.asBroadcastStream();

  Future<int> getAffectedCount() {
    return _stream.length;
  }

  @override
  StreamSubscription<NitriteId> listen(void Function(NitriteId event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
