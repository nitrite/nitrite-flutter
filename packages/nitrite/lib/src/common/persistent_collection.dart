import 'package:nitrite/nitrite.dart';
import 'package:nitrite/src/collection/events/event_aware.dart';
import 'package:nitrite/src/common/initializable.dart';

/// A persistent collection interface that provides methods to manage and
/// manipulate data in a Nitrite database.
abstract class PersistentCollection<T>
    implements EventAware, AttributesAware, Initializable {
  /// Adds a data processor to this collection.
  void addProcessor(Processor processor);

  /// Creates an index on the [fields], if not already exists.
  /// If [indexOptions] is `null`, it will use default options.
  ///
  /// The default indexing option is -
  ///
  /// ```dart
  /// indexOptions.indexType = IndexType.unique;
  /// ```
  ///
  /// NOTE:
  /// - **_id** field is always indexed.
  /// - But full-text indexing is not supported on **_id** value.
  /// - Indexing on non-comparable value is not supported.
  Future<void> createIndex(List<String> fields, [IndexOptions? indexOptions]);

  /// Rebuilds index on the [fields] if it exists.
  Future<void> rebuildIndex(List<String> fields);

  /// Gets a set of all indices in the collection.
  Future<Iterable<IndexDescriptor>> listIndexes();

  /// Checks if the [fields] is already indexed or not.
  Future<bool> hasIndex(List<String> fields);

  /// Checks if indexing operation is currently ongoing for the [fields].
  Future<bool> isIndexing(List<String> fields);

  /// Drops the index on the [fields].
  Future<void> dropIndex(List<String> fields);

  /// Drops all indices from the collection.
  Future<void> dropAllIndices();

  /// Removes all element from the collection.
  Future<void> clear();

  /// Drops the collection and all of its indices.
  ///
  /// Any further access to a dropped collection would result into
  /// an exception.
  Future<void> drop();

  /// Returns `true` if the collection is dropped; otherwise, `false`.
  bool get isDropped;

  /// Returns `true` if the collection is open; otherwise, `false`.
  bool get isOpen;

  /// Returns the size of the [PersistentCollection].
  Future<int> get size;

  /// Closes this [PersistentCollection].
  Future<void> close();

  /// Returns the [NitriteStore] instance for this collection.
  NitriteStore<Config> getStore<Config extends StoreConfig>();
}
