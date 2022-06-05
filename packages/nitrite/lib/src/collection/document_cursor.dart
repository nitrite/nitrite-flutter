import 'dart:async';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/find_plan.dart';
import 'package:nitrite/src/common/lookup.dart';
import 'package:nitrite/src/common/util/object_utils.dart';
import 'package:rxdart/rxdart.dart';

/// An interface to iterate over [NitriteCollection.find] results. It provides a
/// mechanism to iterate over all [NitriteId]s of the result.
///
/// ```dart
/// // create/open a database
/// var db = Nitrite().builder()
///   .openOrCreate("user", "password");
///
/// // create a collection named - products
/// var collection = db.getCollection("products");
///
/// // returns all ids un-filtered
/// var cursor = collection.find();
///
/// for (var doc in cursor) {
///   // use your logic with the retrieved doc here
///   print(doc.id);
/// }
/// ```
abstract class DocumentCursor extends Stream<Document> {
  /// Gets a filter plan for the query.
  FindPlan get findPlan;

  /// Gets a stream of all the selected keys of the result documents.
  Stream<Document> project(Document projection);

  /// Performs a left outer join with a foreign cursor with the specified
  /// lookup parameters.
  ///
  /// It performs an equality match on the localString to the foreignString
  /// from the documents of the foreign cursor.
  /// If an input document does not contain the localString, the join treats
  /// the field as having a value of `null` for matching purposes.
  Stream<Document> leftJoin(DocumentCursor foreignCursor, LookUp lookup);
}

typedef StreamFactory = Stream<Document> Function();

class DocumentStream extends DocumentCursor {
  final DeferStream<Document> _stream;
  final ProcessorChain _processorChain;
  final FindPlan _findPlan;

  DocumentStream(
      StreamFactory streamFactory, this._processorChain, this._findPlan)
      : _stream = DeferStream(streamFactory, reusable: true);

  @override
  FindPlan get findPlan => _findPlan;

  @override
  Stream<Document> project(Document projection) {
    return _ProjectedDocumentStream(this, projection, _processorChain);
  }

  @override
  Stream<Document> leftJoin(DocumentCursor foreignCursor, LookUp lookup) {
    return _JoinedDocumentStream(this, foreignCursor, lookup, _processorChain);
  }

  @override
  StreamSubscription<Document> listen(void Function(Document event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

class _ProjectedDocumentStream extends StreamView<Document> {
  _ProjectedDocumentStream(Stream<Document> stream, Document projection,
      ProcessorChain processorChain)
      : super(_project(stream, projection, processorChain));

  static Stream<Document> _project(Stream<Document> stream, Document projection,
      ProcessorChain processorChain) {
    return stream.map((doc) {
      var newDoc = Document.emptyDocument();
      for (var field in projection.fields) {
        if (doc.containsField(field)) {
          newDoc.put(field, doc[field]);
        }
      }

      // process the result
      newDoc = processorChain.processAfterRead(newDoc);
      return newDoc;
    });
  }
}

class _JoinedDocumentStream extends StreamView<Document> {
  _JoinedDocumentStream(Stream<Document> stream, DocumentCursor foreignCursor,
      LookUp lookup, ProcessorChain processorChain)
      : super(_join(stream, foreignCursor, lookup, processorChain));

  static Stream<Document> _join(
      Stream<Document> stream,
      DocumentCursor foreignCursor,
      LookUp lookup,
      ProcessorChain processorChain) {
    return stream.asyncMap((localDoc) async {
      // get the foreign document
      var newDoc = localDoc.clone();
      // process the result
      newDoc = processorChain.processAfterRead(newDoc);

      var localObject = newDoc[lookup.localField];
      if (localObject == null) return newDoc;

      var docList = <Document>{};
      await foreignCursor.forEach((foreignDoc) {
        var foreignObject = foreignDoc[lookup.foreignField];
        if (foreignObject != null) {
          if (deepEquals(foreignObject, localObject)) {
            docList.add(foreignDoc);
          }
        }
      });

      // process the result
      if (docList.isNotEmpty) {
        newDoc.put(lookup.targetField, docList);
      }
      return newDoc;
    });
  }
}
