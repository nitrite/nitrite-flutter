import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/async/executor.dart';
import 'package:nitrite/src/common/persistent_collection.dart';

/// Represents a document processor.
abstract class Processor {
  /// Processes a document before writing it into database.
  Future<Document> processBeforeWrite(Document document);

  /// Processes a document after reading from the database.
  Future<Document> processAfterRead(Document document);

  /// Processes all documents of a [PersistentCollection].
  Future<void> process(PersistentCollection collection) async {
    NitriteCollection? nitriteCollection;
    if (collection is NitriteCollection) {
      nitriteCollection = collection;
    } else if (collection is ObjectRepository) {
      var repository = collection;
      nitriteCollection = repository.documentCollection;
    }

    if (nitriteCollection != null) {
      var documentCursor = await nitriteCollection.find();

      var executor = Executor();
      await for (var document in documentCursor) {
        executor.submit(() async {
          // process all documents in parallel
          var processed = await processBeforeWrite(document);
          await nitriteCollection!.update(createUniqueFilter(document),
              processed, updateOptions(insertIfAbsent: false));
        });
      }
      await executor.execute();
    }
  }
}

class ProcessorChain extends Processor {
  final List<Processor> processors = [];

  ProcessorChain([List<Processor> processors = const []]) {
    this.processors.addAll(processors);
  }

  @override
  Future<Document> processBeforeWrite(Document document) async {
    for (var processor in processors) {
      // cannot run in parallel because of the order of the processors
      document = await processor.processBeforeWrite(document);
    }
    return document;
  }

  @override
  Future<Document> processAfterRead(Document document) async {
    for (var processor in processors) {
      // cannot run in parallel because of the order of the processors
      document = await processor.processAfterRead(document);
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
