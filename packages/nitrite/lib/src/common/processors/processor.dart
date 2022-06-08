import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/persistent_collection.dart';
import 'package:nitrite/src/common/util/stream_utils.dart';

import '../../collection/options.dart';

/// Represents a document processor.
abstract class Processor {
  /// Processes a document before writing it into database.
  Document processBeforeWrite(Document document);

  /// Processes a document after reading from the database.
  Document processAfterRead(Document document);

  /// Processes all documents of a [PersistentCollection].
  Future<void> process(PersistentCollection collection) async {
    NitriteCollection? nitriteCollection;
    if (collection is NitriteCollection) {
      nitriteCollection = collection;
    } else if (collection is ObjectRepository) {
      var repository = collection as ObjectRepository;
      nitriteCollection = repository.documentCollection;
    }

    if (nitriteCollection != null) {
      var documentCursor = await nitriteCollection.find();
      await for (var document in documentCursor) {
        var processed = processBeforeWrite(document);
        var writeResult = await nitriteCollection.update(
            createUniqueFilter(document),
            processed,
            updateOptions(insertIfAbsent: false));
        writeResult.listen(noOp);
      }
    }
  }
}

class ProcessorChain extends Processor {
  final List<Processor> processors;

  ProcessorChain([this.processors = const []]);

  @override
  Document processBeforeWrite(Document document) {
    for (var processor in processors) {
      document = processor.processBeforeWrite(document);
    }
    return document;
  }

  @override
  Document processAfterRead(Document document) {
    for (var processor in processors) {
      document = processor.processAfterRead(document);
    }
    return document;
  }

  void add(Processor processor) {
    processors.add(processor);
  }

  void remove(Processor processor) {
    processors.remove(processor);
  }
}
