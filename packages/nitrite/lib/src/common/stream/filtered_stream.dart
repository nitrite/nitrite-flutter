import 'dart:async';

import 'package:nitrite/nitrite.dart';

/// @nodoc
class FilteredStream extends StreamView<Document> {
  FilteredStream(Stream<Document> stream, Filter? filter)
      : super(_filter(stream, filter));

  static Stream<Document> _filter(Stream<Document> stream, Filter? filter) {
    filter = filter ?? all;
    return stream.where((doc) => filter!.apply(doc));
  }
}
