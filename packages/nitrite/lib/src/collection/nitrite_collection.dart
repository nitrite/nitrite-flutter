import 'package:nitrite/src/collection/document.dart';
import 'package:nitrite/src/collection/nitrite_id.dart';
import 'package:nitrite/src/common/concurrent/lock_service.dart';
import 'package:nitrite/src/common/persistent_collection.dart';
import 'package:nitrite/src/nitrite_config.dart';
import 'package:nitrite/src/store/nitrite_map.dart';

/// Represents a named document collection stored in nitrite database.
/// It persists documents into the database. Each document is associated
/// with a unique [NitriteId] in a collection.
///
/// A nitrite collection supports indexing. Every nitrite collection is also
/// observable.
///
/// **Create a collection**
///
/// ```dart
/// var db = Nitrite().builder()
///    .openOrCreate("user", "password");
///
/// var collection = db.getCollection("products");
/// ```
abstract class NitriteCollection extends PersistentCollection<Document> {




  bool get isDropped;
  bool get isOpen;
  Future<void> close();

  static create(String name, NitriteMap<NitriteId, Document> nitriteMap, NitriteConfig nitriteConfig, LockService lockService) {}

  find() {}
  update(dynamic filter, dynamic doc, dynamic option);
}
