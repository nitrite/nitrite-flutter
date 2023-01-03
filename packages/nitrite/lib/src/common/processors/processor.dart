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
      var tempMap = await _getTemporaryMap(collection);
      print(1.1);
      await for (var document in documentCursor) {
        tempMap.put(document.id, document);
        // executor.submit(() async {
        //   // process all documents in parallel
        //   var processed = await processBeforeWrite(document);
        //   await tempMap.put(document.id, processed);
        // });
      }
      // await executor.execute();
      print(1.2);
      // executor = Executor();
      await for (var entry in tempMap.entries()) {
        executor.submit(() async {
          print('1.2.1');
          var processed = await processBeforeWrite(entry.second);
          print('1.2.2');
          print(processed);
          await nitriteCollection!.update(byId(entry.first), processed,
              updateOptions(insertIfAbsent: false));
          print('1.2.3');
        });
      }

      await executor.execute();
      await tempMap.drop();
      print(1.3);
    }
  }

  Future<NitriteMap<NitriteId, Document>> _getTemporaryMap(
      PersistentCollection collection) async {
    var store = collection.getStore();
    var name = collection is NitriteCollection
        ? collection.name
        : (collection as ObjectRepository).documentCollection?.name;

    return store.openMap<NitriteId, Document>('${name!}|__temp');
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
      print('1.2.2.1.2.2.1.1');
      print(document);
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
