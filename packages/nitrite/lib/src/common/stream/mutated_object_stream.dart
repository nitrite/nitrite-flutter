import 'dart:async';

import 'package:nitrite/nitrite.dart';

/// @nodoc
class MutatedObjectStream<T> extends StreamView<T> {
  MutatedObjectStream(
      Stream<Document> documentStream, NitriteMapper nitriteMapper,
      [bool stripId = true])
      : super(_mutate<T>(documentStream, nitriteMapper, stripId));

  static Stream<M> _mutate<M>(Stream<Document> documentStream,
      NitriteMapper nitriteMapper, bool stripId) {
    return documentStream.map((document) {
      var record = document.clone();
      if (stripId) {
        record.remove(docId);
      }

      return nitriteMapper.tryConvert<M, Document>(record)!;
    });
  }
}
