import 'dart:async';

import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/processors/processor.dart';
import 'package:nitrite/src/common/stream/joined_document_stream.dart';
import 'package:nitrite/src/common/stream/processed_document_stream.dart';
import 'package:nitrite/src/common/stream/projected_document_stream.dart';

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
/// await for (var doc in cursor) {
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

class DocumentStream extends DocumentCursor {
  final Stream<Document> _stream;
  final FindPlan _findPlan;

  DocumentStream(StreamFactory<Document> streamFactory,
      ProcessorChain processorChain, this._findPlan)
      : _stream = ProcessedDocumentStream(streamFactory, processorChain);

  @override
  FindPlan get findPlan => _findPlan;

  @override
  Stream<Document> project(Document projection) {
    return ProjectedDocumentStream(this, projection);
  }

  @override
  Stream<Document> leftJoin(DocumentCursor foreignCursor, LookUp lookup) {
    return JoinedDocumentStream(this, foreignCursor, lookup);
  }

  @override
  StreamSubscription<Document> listen(void Function(Document event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}
