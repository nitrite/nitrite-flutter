import 'dart:async';

import 'package:nitrite/nitrite.dart';
import 'package:rxdart/rxdart.dart';

abstract class WriteResult extends Stream<NitriteId> {
  Future<int> getAffectedCount();
}

class WriteResultImpl extends WriteResult {
  final ReplaySubject<NitriteId> _subject;

  WriteResultImpl() : _subject = ReplaySubject();

  @override
  Future<int> getAffectedCount() async {
    return _subject.values.length;
  }

  @override
  StreamSubscription<NitriteId> listen(void Function(NitriteId event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _subject.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
