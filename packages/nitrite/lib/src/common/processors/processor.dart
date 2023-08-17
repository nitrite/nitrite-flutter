import 'package:nitrite/nitrite.dart';

/// A class that provides methods to process a document before
/// writing it into database or after reading from the database.
abstract class Processor {
  /// Processes a document before writing it into database.
  Future<Document> processBeforeWrite(Document document);

  /// Processes a document after reading from the database.
  Future<Document> processAfterRead(Document document);

  /// Processes documents in a persistent collection, updates them,
  /// and saves the changes back to the collection.
  ///
  /// Args:
  ///   collection (PersistentCollection): The [collection] parameter is of
  /// type [PersistentCollection]. It can be either a [NitriteCollection]
  /// or an [ObjectRepository].
  Future<void> process(PersistentCollection collection) async {
    NitriteCollection? nitriteCollection;
    if (collection is NitriteCollection) {
      nitriteCollection = collection;
    } else if (collection is ObjectRepository) {
      var repository = collection;
      nitriteCollection = repository.documentCollection;
    }

    if (nitriteCollection != null) {
      var documentCursor = nitriteCollection.find();

      await for (var document in documentCursor) {
        // process all documents in parallel
        var processed = await processBeforeWrite(document);
        await nitriteCollection.update(createUniqueFilter(document), processed,
            updateOptions(insertIfAbsent: false));
      }
    }
  }
}

/// @nodoc
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
