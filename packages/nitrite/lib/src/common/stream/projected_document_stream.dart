import 'dart:async';

import 'package:nitrite/nitrite.dart';

class ProjectedDocumentStream extends StreamView<Document> {
  ProjectedDocumentStream(Stream<Document> stream, Document projection)
      : super(_project(stream, projection));

  static Stream<Document> _project(
      Stream<Document> stream, Document projection) {
    return stream.map((doc) {
      var newDoc = emptyDocument();
      for (var field in projection.fields) {
        if (doc.containsField(field)) {
          newDoc.put(field, doc[field]);
        }
      }

      return newDoc;
    });
  }
}
