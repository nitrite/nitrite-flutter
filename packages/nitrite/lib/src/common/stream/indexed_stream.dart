import 'dart:async';

import 'package:nitrite/nitrite.dart';

class IndexedStream extends StreamView<Document> {
  IndexedStream(
      Stream<NitriteId> stream, NitriteMap<NitriteId, Document> nitriteMap)
      : super(_transform(stream, nitriteMap));

  static Stream<Document> _transform(Stream<NitriteId> stream,
      NitriteMap<NitriteId, Document> nitriteMap) async* {
    await for (var id in stream) {
      var doc = await nitriteMap[id];
      yield doc!;
    }
  }
}
