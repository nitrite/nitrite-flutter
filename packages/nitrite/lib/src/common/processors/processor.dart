
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/common/persistent_collection.dart';

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
      nitriteCollection = collection as NitriteCollection;
    } else if (collection is ObjectRepository) {
      var repository = collection as ObjectRepository;
      nitriteCollection = repository.documentCollection;
    }

    if (nitriteCollection != null) {
      await for (var document in nitriteCollection.find()) {
        var processed = processBeforeWrite(document);
        await nitriteCollection.update(createUniqueFilter(document), processed,
            updateOptions(false));
      }
    }
  }
}
