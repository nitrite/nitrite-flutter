import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/document_cursor.dart';
import 'package:nitrite/src/collection/options.dart';
import 'package:nitrite/src/common/concurrent/lock_service.dart';
import 'package:nitrite/src/common/persistent_collection.dart';
import 'package:nitrite/src/common/write_result.dart';

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
  WriteResult insert(List<Document> documents);

  WriteResult update(List<Document> documents,
      {Filter filter, Document update, UpdateOptions updateOptions});

  WriteResult remove(Filter filter, {Document document, bool justOne});

  DocumentCursor find([Filter filter, FindOptions findOptions]);

  Future<Document> getById(NitriteId id);

  String get name;
}
