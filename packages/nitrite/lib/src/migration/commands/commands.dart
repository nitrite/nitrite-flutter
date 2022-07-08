import 'package:event_bus/event_bus.dart';
import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/operations/collection_operations.dart';

/// Represents a database migration command.
abstract class Command {
  /// Executes a migration step on the database.
  Future<void> execute(Nitrite nitrite);

  /// Closes the command and release any resource held.
  Future<void> close() async {}
}

abstract class BaseCommand implements Command {
  NitriteStore? nitriteStore;
  NitriteMap<NitriteId, Document>? nitriteMap;
  CollectionOperations? operations;

  @override
  Future<void> close() async {
    if (operations != null) {
      await operations?.close();
    }
  }

  Future<void> initialize(Nitrite nitrite, String collectionName) async {
    nitriteStore = nitrite.getStore();
    nitriteMap =
        await nitriteStore?.openMap<NitriteId, Document>(collectionName);
    operations = CollectionOperations(
        collectionName, nitriteMap!, nitrite.config, EventBus());
    await operations?.initialize();
  }
}
