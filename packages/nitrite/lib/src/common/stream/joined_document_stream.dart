import 'dart:async';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/util/object_utils.dart';

class JoinedDocumentStream extends StreamView<Document> {
  JoinedDocumentStream(
      Stream<Document> stream, DocumentCursor foreignCursor, LookUp lookup)
      : super(_join(stream, foreignCursor, lookup));

  static Stream<Document> _join(
      Stream<Document> stream, DocumentCursor foreignCursor, LookUp lookup) {
    return stream.asyncMap((localDoc) async {
      // get the foreign document
      var newDoc = localDoc.clone();

      var localObject = newDoc[lookup.localField];
      if (localObject == null) return newDoc;

      var docList = <Document>{};
      await for (var foreignDoc in foreignCursor) {
        var foreignObject = foreignDoc[lookup.foreignField];
        if (foreignObject != null) {
          if (deepEquals(foreignObject, localObject)) {
            docList.add(foreignDoc);
          }
        }
      }

      // process the result
      if (docList.isNotEmpty) {
        newDoc.put(lookup.targetField, docList);
      }
      return newDoc;
    });
  }
}
